import React, { useEffect, useState } from 'react';
import {
  collection, query, where, orderBy, onSnapshot,
  doc, getDoc, getDocs,
} from 'firebase/firestore';
import { signOut } from 'firebase/auth';
import { db, auth } from '../firebase.js';

function formatTime(timestamp) {
  if (!timestamp) return '';
  const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
  const now = new Date();
  const diffDays = Math.floor((now - date) / 86400000);
  if (diffDays === 0) return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return date.toLocaleDateString([], { weekday: 'short' });
  return date.toLocaleDateString([], { month: 'short', day: 'numeric' });
}

function Avatar({ user, size = 40 }) {
  if (user?.photoURL) {
    return (
      <img
        src={user.photoURL}
        alt={user.displayName || 'User'}
        className="avatar"
        style={{ width: size, height: size }}
        onError={(e) => { e.target.style.display = 'none'; }}
      />
    );
  }
  const initials = (user?.displayName || user?.email || '?')[0].toUpperCase();
  return (
    <div className="avatar avatar-fallback" style={{ width: size, height: size, fontSize: size * 0.4 }}>
      {initials}
    </div>
  );
}

export default function ChatList({ currentUser, activeChat, onSelectChat }) {
  const [chats, setChats] = useState([]);
  const [userCache, setUserCache] = useState({});
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [allUsers, setAllUsers] = useState([]);
  const [showUsers, setShowUsers] = useState(false);

  useEffect(() => {
    if (!db || !currentUser) return;

    const q = query(
      collection(db, 'chats'),
      where('participants', 'array-contains', currentUser.uid),
      orderBy('lastMessageTime', 'desc')
    );

    const unsubscribe = onSnapshot(q, async (snapshot) => {
      const chatDocs = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }));

      // Collect all peer UIDs not yet in cache
      const unknownUids = [];
      chatDocs.forEach((chat) => {
        const peerId = chat.participants.find((uid) => uid !== currentUser.uid);
        if (peerId && !userCache[peerId]) unknownUids.push(peerId);
      });

      if (unknownUids.length > 0) {
        const fetched = {};
        await Promise.all(
          unknownUids.map(async (uid) => {
            try {
              const snap = await getDoc(doc(db, 'users', uid));
              if (snap.exists()) fetched[uid] = snap.data();
            } catch (_) {}
          })
        );
        setUserCache((prev) => ({ ...prev, ...fetched }));
      }

      setChats(chatDocs);
      setLoading(false);
    }, (err) => {
      console.error('[ChatList] Snapshot error:', err);
      setLoading(false);
    });

    return () => unsubscribe();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentUser]);

  const handleNewChat = async () => {
    if (!db) return;
    setShowUsers(true);
    try {
      const snap = await getDocs(collection(db, 'users'));
      setAllUsers(
        snap.docs
          .map((d) => d.data())
          .filter((u) => u.uid !== currentUser.uid)
      );
    } catch (err) {
      console.error('[ChatList] Failed to load users:', err);
    }
  };

  const startChat = async (peer) => {
    if (!db) return;
    setShowUsers(false);
    const ids = [currentUser.uid, peer.uid].sort();
    const chatId = ids.join('_');

    const existing = chats.find((c) => c.id === chatId);
    if (existing) {
      onSelectChat(existing);
      return;
    }

    const { setDoc, doc: firestoreDoc, serverTimestamp } = await import('firebase/firestore');
    try {
      await setDoc(firestoreDoc(db, 'chats', chatId), {
        participants: ids,
        lastMessage: '',
        lastMessageTime: serverTimestamp(),
        typing: {},
      }, { merge: true });
      onSelectChat({ id: chatId, participants: ids, lastMessage: '', peerUser: peer });
    } catch (err) {
      console.error('[ChatList] Failed to create chat:', err);
    }
  };

  const filteredChats = chats.filter((chat) => {
    const peerId = chat.participants.find((uid) => uid !== currentUser.uid);
    const peer = userCache[peerId];
    return !searchQuery || peer?.displayName?.toLowerCase().includes(searchQuery.toLowerCase());
  });

  return (
    <aside className="chat-list">
      <header className="chat-list-header">
        <div className="chat-list-header-top">
          <Avatar user={currentUser} size={36} />
          <h2 className="brand-small">Sambhasha</h2>
          <div className="header-actions">
            <button
              className="icon-btn"
              title="New chat"
              onClick={handleNewChat}
              aria-label="Start new chat"
            >
              ✏️
            </button>
            <button
              className="icon-btn"
              title="Sign out"
              onClick={() => signOut(auth)}
              aria-label="Sign out"
            >
              🚪
            </button>
          </div>
        </div>
        <input
          className="search-input"
          type="search"
          placeholder="Search conversations…"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          aria-label="Search conversations"
        />
      </header>

      {showUsers && (
        <div className="user-picker">
          <div className="user-picker-header">
            <span>Start a new chat</span>
            <button className="icon-btn" onClick={() => setShowUsers(false)}>✕</button>
          </div>
          {allUsers.length === 0 ? (
            <p className="empty-msg">No other users yet.</p>
          ) : (
            allUsers.map((u) => (
              <button key={u.uid} className="user-picker-item" onClick={() => startChat(u)}>
                <Avatar user={u} size={36} />
                <span>{u.displayName || u.email}</span>
              </button>
            ))
          )}
        </div>
      )}

      <div className="chat-list-body">
        {loading && <div className="loading-msg">Loading chats…</div>}
        {!loading && filteredChats.length === 0 && (
          <div className="empty-msg">
            {searchQuery ? 'No matching chats.' : 'No conversations yet. Start one! ✏️'}
          </div>
        )}
        {filteredChats.map((chat) => {
          const peerId = chat.participants.find((uid) => uid !== currentUser.uid);
          const peer = userCache[peerId] || { displayName: 'Unknown', uid: peerId };
          const isActive = activeChat?.id === chat.id;
          return (
            <button
              key={chat.id}
              className={`chat-item ${isActive ? 'chat-item-active' : ''}`}
              onClick={() => onSelectChat({ ...chat, peerUser: peer })}
              aria-pressed={isActive}
            >
              <div className="chat-item-avatar-wrap">
                <Avatar user={peer} size={46} />
                {peer.isOnline && <span className="online-dot" aria-label="Online" />}
              </div>
              <div className="chat-item-info">
                <div className="chat-item-top">
                  <span className="chat-item-name">{peer.displayName || peer.email || 'Unknown'}</span>
                  <span className="chat-item-time">{formatTime(chat.lastMessageTime)}</span>
                </div>
                <div className="chat-item-last-msg">
                  {chat.lastMessage || <em>No messages yet</em>}
                </div>
              </div>
            </button>
          );
        })}
      </div>
    </aside>
  );
}
