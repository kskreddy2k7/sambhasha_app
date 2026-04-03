export interface User {
  id: string;
  name: string;
  avatar: string;
  online: boolean;
  email?: string;
  status?: string;
}

export interface Chat {
  id: string;
  name: string;
  avatar: string;
  lastMessage: string;
  time: string;
  unread: boolean;
  unreadCount: number;
  online: boolean;
  type?: 'text' | 'typing';
}

export interface Story {
  id: string;
  userId: string;
  imageUrl: string;
  timestamp: string;
  location?: string;
}

export interface Message {
  messageId: string;
  senderId: string;
  text: string;
  timestamp: any; // Firestore Timestamp
  read: boolean;
  type?: 'text' | 'image' | 'video' | 'audio';
  isAi?: boolean;
}
