import { 
  collection, 
  query, 
  where, 
  onSnapshot, 
  addDoc, 
  serverTimestamp, 
  orderBy,
  updateDoc,
  doc,
  getDoc,
  setDoc,
  limit
} from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { Chat, Message, User } from '../types';

export const chatService = {
  // 1. Get user chats
  subscribeToChats: (callback: (chats: Chat[]) => void) => {
    const user = auth.currentUser;
    if (!user) return;

    const q = query(
      collection(db, 'chats'),
      where('participants', 'array-contains', user.uid),
      orderBy('lastMessageTime', 'desc')
    );

    return onSnapshot(q, (snapshot) => {
      const chats = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })) as Chat[];
      callback(chats);
    });
  },

  // 2. Get messages for a chat
  subscribeToMessages: (chatId: string, callback: (messages: Message[]) => void) => {
    const q = query(
      collection(db, 'chats', chatId, 'messages'),
      orderBy('timestamp', 'asc'),
      limit(100)
    );

    return onSnapshot(q, (snapshot) => {
      const messages = snapshot.docs.map(doc => ({
        messageId: doc.id,
        ...doc.data()
      })) as Message[];
      callback(messages);
    });
  },

  // 3. Send a message
  sendMessage: async (chatId: string, content: string, type: 'text' | 'image' | 'video' | 'audio' = 'text') => {
    const user = auth.currentUser;
    if (!user) return;

    const messageData = {
      senderId: user.uid,
      text: content,
      type,
      timestamp: serverTimestamp(),
      read: false,
      messageId: '' // Will be updated below
    };

    // Add message to subcollection
    const docRef = await addDoc(collection(db, 'chats', chatId, 'messages'), messageData);
    await updateDoc(docRef, { messageId: docRef.id });

    // Update parent chat doc
    await updateDoc(doc(db, 'chats', chatId), {
      lastMessage: content,
      lastMessageTime: serverTimestamp(),
      lastMessageId: docRef.id
    });
  },

  // 4. Update user profile/status
  updateUserStatus: async (online: boolean) => {
    const user = auth.currentUser;
    if (!user) return;

    await setDoc(doc(db, 'users', user.uid), {
      lastSeen: serverTimestamp(),
      online: online
    }, { merge: true });
  }
};
