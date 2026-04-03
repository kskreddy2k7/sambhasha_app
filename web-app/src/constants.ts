import { User, Chat } from './types';

export const currentUser: User = {
  id: 'me',
  name: 'Ksk Reddy',
  avatar: 'https://avatar.iran.liara.run/public/boy?username=kskreddy',
  online: true,
  email: 'kskreddy@example.com'
};

export const users: User[] = [
  {
    id: 'u1',
    name: 'Sarah Jenkins',
    avatar: 'https://avatar.iran.liara.run/public/girl?username=sarah',
    online: true,
    status: 'Design is thinking made visual.'
  },
  {
    id: 'u2',
    name: 'Julian Chen',
    avatar: 'https://avatar.iran.liara.run/public/boy?username=julian',
    online: true,
    status: 'In a meeting'
  },
  {
    id: 'u3',
    name: 'Aisha Malik',
    avatar: 'https://avatar.iran.liara.run/public/girl?username=aisha',
    online: false,
    status: 'Offline'
  }
];

export const chats: Chat[] = [
  {
    id: 'c1',
    name: 'Sarah Jenkins',
    avatar: 'https://avatar.iran.liara.run/public/girl?username=sarah',
    lastMessage: 'Let\'s finalize the design sprint...',
    time: '10:45 AM',
    unread: true,
    unreadCount: 2,
    online: true
  },
  {
    id: 'c2',
    name: 'Julian Chen',
    avatar: 'https://avatar.iran.liara.run/public/boy?username=julian',
    lastMessage: 'Transcription ready for the call.',
    time: '9:30 AM',
    unread: false,
    unreadCount: 0,
    online: true,
    type: 'typing'
  }
];
