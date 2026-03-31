"use strict";

require("dotenv").config();

const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const cors = require("cors");

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const PORT = parseInt(process.env.PORT || "3001", 10);

const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(",").map((o) => o.trim())
  : "*";

// ---------------------------------------------------------------------------
// In-memory state — declared early so route handlers can reference it
// rooms: Map<callId, Map<userId, socketId>>
// ---------------------------------------------------------------------------
const rooms = new Map();

// ---------------------------------------------------------------------------
// Express + HTTP server
// ---------------------------------------------------------------------------
const app = express();

app.use(
  cors({
    origin: allowedOrigins,
    methods: ["GET", "POST"],
  })
);

app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({
    status: "ok",
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    rooms: rooms.size,
  });
});

// Catch-all for unknown routes
app.use((_req, res) => {
  res.status(404).json({ error: "Not found" });
});

const httpServer = http.createServer(app);

// ---------------------------------------------------------------------------
// Socket.IO
// ---------------------------------------------------------------------------
const io = new Server(httpServer, {
  cors: {
    origin: allowedOrigins,
    methods: ["GET", "POST"],
  },
  // Graceful ping/pong to detect dead connections
  pingTimeout: 60000,
  pingInterval: 25000,
});



/** Return the room map for callId, creating it if needed. */
function getRoom(callId) {
  if (!rooms.has(callId)) {
    rooms.set(callId, new Map());
  }
  return rooms.get(callId);
}

/** Remove a user from every room they are tracked in (by socketId). */
function removeSocketFromAllRooms(socketId) {
  for (const [callId, members] of rooms.entries()) {
    for (const [userId, sid] of members.entries()) {
      if (sid === socketId) {
        members.delete(userId);
        if (members.size === 0) {
          rooms.delete(callId);
        }
        return { callId, userId };
      }
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Socket event handlers
// ---------------------------------------------------------------------------
io.on("connection", (socket) => {
  console.log(`[connect]  socket=${socket.id}`);

  // -------------------------------------------------------------------------
  // join-call
  // Payload: { callId: string, userId: string }
  // -------------------------------------------------------------------------
  socket.on("join-call", ({ callId, userId } = {}) => {
    if (!callId || !userId) {
      socket.emit("error", { message: "join-call requires callId and userId" });
      return;
    }

    const room = getRoom(callId);

    if (room.size >= 2) {
      socket.emit("call-full", { callId });
      return;
    }

    // Remove any stale entry for this userId in this room
    room.set(userId, socket.id);
    socket.join(callId);

    console.log(`[join-call] callId=${callId} userId=${userId} socket=${socket.id} peers=${room.size}`);

    // Tell everyone else in the room that a new peer has joined
    socket.to(callId).emit("peer-joined", { callId, userId });

    // Acknowledge the join to the caller
    socket.emit("joined-call", {
      callId,
      userId,
      peers: [...room.keys()].filter((id) => id !== userId),
    });
  });

  // -------------------------------------------------------------------------
  // leave-call
  // Payload: { callId: string }
  // -------------------------------------------------------------------------
  socket.on("leave-call", ({ callId } = {}) => {
    if (!callId) return;
    handleLeave(socket, callId);
  });

  // -------------------------------------------------------------------------
  // offer
  // Payload: { callId, offer, to }   – `to` is the target userId
  // -------------------------------------------------------------------------
  socket.on("offer", ({ callId, offer, to } = {}) => {
    if (!callId || !offer || !to) {
      socket.emit("error", { message: "offer requires callId, offer, and to" });
      return;
    }

    const targetSocketId = resolveTarget(callId, to);
    if (!targetSocketId) {
      socket.emit("error", { message: `Peer ${to} not found in call ${callId}` });
      return;
    }

    console.log(`[offer]    callId=${callId} → ${to}`);
    io.to(targetSocketId).emit("offer", { callId, offer, from: getUserIdBySocket(callId, socket.id) });
  });

  // -------------------------------------------------------------------------
  // answer
  // Payload: { callId, answer, to }
  // -------------------------------------------------------------------------
  socket.on("answer", ({ callId, answer, to } = {}) => {
    if (!callId || !answer || !to) {
      socket.emit("error", { message: "answer requires callId, answer, and to" });
      return;
    }

    const targetSocketId = resolveTarget(callId, to);
    if (!targetSocketId) {
      socket.emit("error", { message: `Peer ${to} not found in call ${callId}` });
      return;
    }

    console.log(`[answer]   callId=${callId} → ${to}`);
    io.to(targetSocketId).emit("answer", { callId, answer, from: getUserIdBySocket(callId, socket.id) });
  });

  // -------------------------------------------------------------------------
  // ice-candidate
  // Payload: { callId, candidate, to }
  // -------------------------------------------------------------------------
  socket.on("ice-candidate", ({ callId, candidate, to } = {}) => {
    if (!callId || !candidate || !to) {
      socket.emit("error", { message: "ice-candidate requires callId, candidate, and to" });
      return;
    }

    const targetSocketId = resolveTarget(callId, to);
    if (!targetSocketId) {
      // Silently drop late/stale ICE candidates
      return;
    }

    io.to(targetSocketId).emit("ice-candidate", {
      callId,
      candidate,
      from: getUserIdBySocket(callId, socket.id),
    });
  });

  // -------------------------------------------------------------------------
  // call-rejected
  // Payload: { callId }  – notifies the other peer in the room
  // -------------------------------------------------------------------------
  socket.on("call-rejected", ({ callId } = {}) => {
    if (!callId) return;
    console.log(`[rejected] callId=${callId} socket=${socket.id}`);
    socket.to(callId).emit("call-rejected", { callId });
    handleLeave(socket, callId);
  });

  // -------------------------------------------------------------------------
  // disconnection — clean up any rooms the socket was part of
  // -------------------------------------------------------------------------
  socket.on("disconnect", (reason) => {
    console.log(`[disconnect] socket=${socket.id} reason=${reason}`);
    const entry = removeSocketFromAllRooms(socket.id);
    if (entry) {
      const { callId, userId } = entry;
      io.to(callId).emit("peer-left", { callId, userId });
      console.log(`[auto-leave] callId=${callId} userId=${userId}`);
    }
  });
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Gracefully remove a socket from a specific call room. */
function handleLeave(socket, callId) {
  const room = rooms.get(callId);
  if (!room) return;

  let leavingUserId;
  for (const [userId, sid] of room.entries()) {
    if (sid === socket.id) {
      leavingUserId = userId;
      break;
    }
  }

  if (leavingUserId) {
    room.delete(leavingUserId);
    if (room.size === 0) rooms.delete(callId);
  }

  socket.leave(callId);
  socket.to(callId).emit("peer-left", { callId, userId: leavingUserId });
  console.log(`[leave-call] callId=${callId} userId=${leavingUserId}`);
}

/** Resolve a userId to their current socketId within a room. */
function resolveTarget(callId, userId) {
  const room = rooms.get(callId);
  if (!room) return null;
  return room.get(userId) || null;
}

/** Reverse-lookup: find userId by socketId inside a room. */
function getUserIdBySocket(callId, socketId) {
  const room = rooms.get(callId);
  if (!room) return null;
  for (const [userId, sid] of room.entries()) {
    if (sid === socketId) return userId;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------
httpServer.listen(PORT, () => {
  console.log(`Signaling server listening on port ${PORT}`);
  console.log(`Allowed origins: ${JSON.stringify(allowedOrigins)}`);
});

// Graceful shutdown
function shutdown(signal) {
  console.log(`Received ${signal}. Shutting down…`);
  io.close(() => {
    httpServer.close(() => {
      console.log("Server closed.");
      process.exit(0);
    });
  });
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));
