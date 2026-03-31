import React, { useEffect, useState } from 'react';
import { onAuthStateChanged } from 'firebase/auth';
import { doc, setDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db, isFirebaseConfigured } from './firebase.js';
import LoginScreen from './components/LoginScreen.jsx';
import ChatList from './components/ChatList.jsx';
import ChatScreen from './components/ChatScreen.jsx';

function FirebaseNotConfigured() {
  return (
    <div className="config-error">
      <div className="config-error-card">
        <h1 className="brand">Sambhasha</h1>
        <div className="config-error-icon">⚙️</div>
        <h2>Firebase Not Configured</h2>
        <p>
          Copy <code>.env.example</code> to <code>.env</code> and fill in your
          Firebase project credentials to get started.
        </p>
        <ol>
          <li>Create a Firebase project at <a href="https://console.firebase.google.com" target="_blank" rel="noreferrer">console.firebase.google.com</a></li>
          <li>Enable Authentication → Google sign-in</li>
          <li>Enable Firestore Database</li>
          <li>Copy your web app config values into <code>.env</code></li>
          <li>Restart the dev server</li>
        </ol>
      </div>
    </div>
  );
}

export default function App() {
  const [user, setUser] = useState(undefined); // undefined = loading
  const [activeChat, setActiveChat] = useState(null);
  const [inCall, setInCall] = useState(false);

  useEffect(() => {
    if (!isFirebaseConfigured || !auth) {
      setUser(null);
      return;
    }

    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        try {
          await setDoc(
            doc(db, 'users', firebaseUser.uid),
            {
              uid: firebaseUser.uid,
              displayName: firebaseUser.displayName,
              photoURL: firebaseUser.photoURL,
              email: firebaseUser.email,
              isOnline: true,
              lastSeen: serverTimestamp(),
            },
            { merge: true }
          );
        } catch (err) {
          console.error('[App] Failed to update user doc:', err);
        }
      } else {
        // Mark offline on sign-out if we had a previous user
        if (user?.uid) {
          try {
            await setDoc(
              doc(db, 'users', user.uid),
              { isOnline: false, lastSeen: serverTimestamp() },
              { merge: true }
            );
          } catch (_) {}
        }
      }
      setUser(firebaseUser || null);
    });

    return () => unsubscribe();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (!isFirebaseConfigured) return <FirebaseNotConfigured />;

  if (user === undefined) {
    return (
      <div className="splash">
        <h1 className="brand">Sambhasha</h1>
        <div className="spinner" />
      </div>
    );
  }

  if (!user) return <LoginScreen />;

  return (
    <div className="app-layout">
      <ChatList
        currentUser={user}
        activeChat={activeChat}
        onSelectChat={setActiveChat}
      />
      <div className="chat-area">
        {activeChat ? (
          <ChatScreen
            currentUser={user}
            chat={activeChat}
            onBack={() => setActiveChat(null)}
            inCall={inCall}
            setInCall={setInCall}
          />
        ) : (
          <div className="no-chat-selected">
            <div className="no-chat-icon">💬</div>
            <h2>Welcome to Sambhasha</h2>
            <p>Select a conversation to start chatting</p>
          </div>
        )}
      </div>
    </div>
  );
}
