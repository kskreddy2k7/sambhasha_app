import { useEffect, useRef, useState, useCallback } from 'react';
import { io } from 'socket.io-client';

const STUN_SERVERS = {
  iceServers: [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' },
  ],
};

const SIGNALING_URL = import.meta.env.VITE_SIGNALING_SERVER_URL || '';

export default function useWebRTC({ currentUserId, peerId, chatId, enabled }) {
  const [localStream, setLocalStream] = useState(null);
  const [remoteStream, setRemoteStream] = useState(null);
  const [callState, setCallState] = useState('idle'); // idle | calling | connected | ended
  const [isMuted, setIsMuted] = useState(false);
  const [isCameraOff, setIsCameraOff] = useState(false);
  const [signalingError, setSignalingError] = useState('');

  const pcRef = useRef(null);
  const socketRef = useRef(null);
  const localStreamRef = useRef(null);

  // Initialise Socket.IO connection
  useEffect(() => {
    if (!enabled || !SIGNALING_URL) {
      if (!SIGNALING_URL) {
        setSignalingError(
          'Signaling server URL not configured. ' +
          'Set VITE_SIGNALING_SERVER_URL in your .env file (see .env.example).'
        );
      }
      return;
    }

    const socket = io(SIGNALING_URL, {
      transports: ['websocket'],
      reconnectionAttempts: 5,
    });

    socket.on('connect', () => {
      socket.emit('join', { room: chatId, userId: currentUserId });
      setSignalingError('');
    });

    socket.on('connect_error', (err) => {
      setSignalingError(`Signaling server unreachable: ${err.message}`);
    });

    socket.on('offer', async ({ offer, from }) => {
      if (from === currentUserId) return;
      try {
        const pc = createPeerConnection(socket);
        pcRef.current = pc;
        await pc.setRemoteDescription(new RTCSessionDescription(offer));

        const stream = await getUserMedia();
        stream.getTracks().forEach((t) => pc.addTrack(t, stream));

        const answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        socket.emit('answer', { answer, to: from, from: currentUserId, room: chatId });
        setCallState('connected');
      } catch (err) {
        console.error('[useWebRTC] Error handling offer:', err);
      }
    });

    socket.on('answer', async ({ answer }) => {
      try {
        await pcRef.current?.setRemoteDescription(new RTCSessionDescription(answer));
        setCallState('connected');
      } catch (err) {
        console.error('[useWebRTC] Error handling answer:', err);
      }
    });

    socket.on('ice-candidate', async ({ candidate }) => {
      try {
        if (candidate && pcRef.current) {
          await pcRef.current.addIceCandidate(new RTCIceCandidate(candidate));
        }
      } catch (err) {
        console.error('[useWebRTC] ICE candidate error:', err);
      }
    });

    socket.on('call-ended', () => {
      cleanup();
      setCallState('ended');
    });

    socketRef.current = socket;

    return () => {
      socket.disconnect();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [enabled, chatId, currentUserId]);

  const getUserMedia = async () => {
    const stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
    localStreamRef.current = stream;
    setLocalStream(stream);
    return stream;
  };

  const createPeerConnection = useCallback((socket) => {
    const pc = new RTCPeerConnection(STUN_SERVERS);

    pc.onicecandidate = ({ candidate }) => {
      if (candidate) {
        socket.emit('ice-candidate', { candidate, to: peerId, room: chatId });
      }
    };

    pc.ontrack = ({ streams }) => {
      setRemoteStream(streams[0]);
    };

    pc.onconnectionstatechange = () => {
      if (pc.connectionState === 'disconnected' || pc.connectionState === 'failed') {
        setCallState('ended');
      }
    };

    return pc;
  }, [peerId, chatId]);

  const startCall = useCallback(async () => {
    if (!socketRef.current?.connected) {
      setSignalingError('Not connected to signaling server.');
      return;
    }
    try {
      setCallState('calling');
      const stream = await getUserMedia();
      const pc = createPeerConnection(socketRef.current);
      pcRef.current = pc;
      stream.getTracks().forEach((t) => pc.addTrack(t, stream));

      const offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      socketRef.current.emit('offer', { offer, to: peerId, from: currentUserId, room: chatId });
    } catch (err) {
      console.error('[useWebRTC] startCall error:', err);
      setCallState('idle');
      if (err.name === 'NotAllowedError') {
        setSignalingError('Camera/microphone permission denied.');
      } else {
        setSignalingError(err.message);
      }
    }
  }, [createPeerConnection, peerId, currentUserId, chatId]);

  const endCall = useCallback(() => {
    socketRef.current?.emit('call-ended', { to: peerId, room: chatId });
    cleanup();
    setCallState('ended');
  }, [peerId, chatId]);

  const cleanup = () => {
    pcRef.current?.close();
    pcRef.current = null;
    localStreamRef.current?.getTracks().forEach((t) => t.stop());
    localStreamRef.current = null;
    setLocalStream(null);
    setRemoteStream(null);
  };

  const toggleMute = useCallback(() => {
    if (!localStreamRef.current) return;
    localStreamRef.current.getAudioTracks().forEach((t) => {
      t.enabled = !t.enabled;
    });
    setIsMuted((prev) => !prev);
  }, []);

  const toggleCamera = useCallback(() => {
    if (!localStreamRef.current) return;
    localStreamRef.current.getVideoTracks().forEach((t) => {
      t.enabled = !t.enabled;
    });
    setIsCameraOff((prev) => !prev);
  }, []);

  return {
    localStream,
    remoteStream,
    callState,
    isMuted,
    isCameraOff,
    signalingError,
    startCall,
    endCall,
    toggleMute,
    toggleCamera,
  };
}
