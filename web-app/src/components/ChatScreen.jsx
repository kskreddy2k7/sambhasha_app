import React, { useEffect, useRef, useState } from 'react';
import {
  collection, query, orderBy, onSnapshot, addDoc,
  serverTimestamp, doc, updateDoc, deleteField, setDoc,
} from 'firebase/firestore';
import { db } from '../firebase.js';
import VideoCall from './VideoCall.jsx';

function formatMessageTime(timestamp) {
  if (!timestamp) return '';
  const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

function StatusTick({ status }) {
  if (status === 'seen') return <span className="msg-tick seen" title="Seen">✓✓</span>;
  if (status === 'delivered') return <span className="msg-tick delivered" title="Delivered">✓✓</span>;
  return <span className="msg-tick" title="Sent">✓</span>;
}

export default function ChatScreen({ currentUser, chat, onBack, inCall, setInCall }) {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [typingPeers, setTypingPeers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const bottomRef = useRef(null);
  const typingTimeoutRef = useRef(null);
  const messagesColRef = collection(db, 'chats', chat.id, 'messages');

  // Subscribe to messages
  useEffect(() => {
    if (!db) return;
    const q = query(messagesColRef, orderBy('timestamp', 'asc'));
    const unsub = onSnapshot(q, (snap) => {
      setMessages(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
      setLoading(false);

      // Mark incoming messages as seen
      snap.docs.forEach(async (d) => {
        const data = d.data();
        if (data.senderId !== currentUser.uid && data.status !== 'seen') {
          try {
            await updateDoc(doc(db, 'chats', chat.id, 'messages', d.id), { status: 'seen' });
          } catch (_) {}
        }
      });
    }, (err) => {
      console.error('[ChatScreen] Messages error:', err);
      setLoading(false);
    });
    return () => unsub();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [chat.id]);

  // Subscribe to typing indicators
  useEffect(() => {
    if (!db) return;
    const chatDocRef = doc(db, 'chats', chat.id);
    const unsub = onSnapshot(chatDocRef, (snap) => {
      const data = snap.data();
      if (!data?.typing) return;
      const peers = Object.entries(data.typing)
        .filter(([uid, isTyping]) => uid !== currentUser.uid && isTyping)
        .map(([uid]) => uid);
      setTypingPeers(peers);
    });
    return () => unsub();
  }, [chat.id, currentUser.uid]);

  // Scroll to bottom on new messages
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, typingPeers]);

  const setTyping = async (isTyping) => {
    if (!db) return;
    try {
      await setDoc(
        doc(db, 'chats', chat.id),
        { typing: { [currentUser.uid]: isTyping } },
        { merge: true }
      );
    } catch (_) {}
  };

  const handleInputChange = (e) => {
    setInput(e.target.value);
    setTyping(true);
    clearTimeout(typingTimeoutRef.current);
    typingTimeoutRef.current = setTimeout(() => setTyping(false), 2000);
  };

  const sendMessage = async (e) => {
    e?.preventDefault();
    const text = input.trim();
    if (!text || sending || !db) return;

    setSending(true);
    setInput('');
    setTyping(false);
    clearTimeout(typingTimeoutRef.current);

    try {
      await addDoc(messagesColRef, {
        senderId: currentUser.uid,
        text,
        timestamp: serverTimestamp(),
        status: 'sent',
      });

      await setDoc(
        doc(db, 'chats', chat.id),
        {
          lastMessage: text,
          lastMessageTime: serverTimestamp(),
          typing: { [currentUser.uid]: deleteField() },
        },
        { merge: true }
      );
    } catch (err) {
      console.error('[ChatScreen] Send error:', err);
    } finally {
      setSending(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  const peer = chat.peerUser || {};

  return (
    <div className="chat-screen">
      {inCall && (
        <VideoCall
          currentUser={currentUser}
          peerId={peer.uid}
          chatId={chat.id}
          onEndCall={() => setInCall(false)}
        />
      )}

      <header className="chat-screen-header">
        <button className="icon-btn back-btn" onClick={onBack} aria-label="Back">‹</button>
        <div className="chat-screen-peer-info">
          <div className="peer-avatar-wrap">
            {peer.photoURL ? (
              <img src={peer.photoURL} alt={peer.displayName} className="avatar" style={{ width: 38, height: 38 }} />
            ) : (
              <div className="avatar avatar-fallback" style={{ width: 38, height: 38 }}>
                {(peer.displayName || '?')[0].toUpperCase()}
              </div>
            )}
            {peer.isOnline && <span className="online-dot" />}
          </div>
          <div>
            <div className="peer-name">{peer.displayName || peer.email || 'Unknown'}</div>
            <div className="peer-status">
              {peer.isOnline ? 'Online' : 'Offline'}
            </div>
          </div>
        </div>
        <div className="chat-screen-actions">
          <button
            className="icon-btn call-btn"
            title="Audio call"
            onClick={() => setInCall(true)}
            aria-label="Start audio call"
          >
            📞
          </button>
          <button
            className="icon-btn call-btn"
            title="Video call"
            onClick={() => setInCall(true)}
            aria-label="Start video call"
          >
            📹
          </button>
        </div>
      </header>

      <div className="messages-area" role="log" aria-live="polite" aria-label="Messages">
        {loading && <div className="loading-msg">Loading messages…</div>}
        {!loading && messages.length === 0 && (
          <div className="empty-msg">No messages yet. Say hi! 👋</div>
        )}
        {messages.map((msg, idx) => {
          const isMine = msg.senderId === currentUser.uid;
          const prevMsg = messages[idx - 1];
          const showDate = !prevMsg || (
            msg.timestamp && prevMsg.timestamp &&
            msg.timestamp.toDate?.().toDateString() !== prevMsg.timestamp.toDate?.().toDateString()
          );
          return (
            <React.Fragment key={msg.id}>
              {showDate && msg.timestamp && (
                <div className="date-divider">
                  {msg.timestamp.toDate?.().toLocaleDateString([], {
                    weekday: 'long', month: 'long', day: 'numeric',
                  })}
                </div>
              )}
              <div className={`message-row ${isMine ? 'mine' : 'theirs'}`}>
                <div className={`bubble ${isMine ? 'bubble-mine' : 'bubble-theirs'}`}>
                  <span className="bubble-text">{msg.text}</span>
                  <div className="bubble-meta">
                    <span className="bubble-time">{formatMessageTime(msg.timestamp)}</span>
                    {isMine && <StatusTick status={msg.status} />}
                  </div>
                </div>
              </div>
            </React.Fragment>
          );
        })}

        {typingPeers.length > 0 && (
          <div className="message-row theirs">
            <div className="bubble bubble-theirs typing-bubble" aria-label="Peer is typing">
              <span className="typing-dot" />
              <span className="typing-dot" />
              <span className="typing-dot" />
            </div>
          </div>
        )}
        <div ref={bottomRef} />
      </div>

      <form className="message-input-bar" onSubmit={sendMessage}>
        <textarea
          className="message-input"
          value={input}
          onChange={handleInputChange}
          onKeyDown={handleKeyDown}
          placeholder="Type a message…"
          rows={1}
          aria-label="Message input"
          disabled={sending}
        />
        <button
          type="submit"
          className="send-btn"
          disabled={!input.trim() || sending}
          aria-label="Send message"
        >
          {sending ? <span className="btn-spinner" /> : '➤'}
        </button>
      </form>
    </div>
  );
}
