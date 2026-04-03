import { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { Search, Filter, Camera, Edit3, Sparkles, Send, Paperclip, Smile, Mic, Video, Phone, Info } from 'lucide-react';
import { Sidebar, BottomNav } from '../components/Navigation';
import { cn } from '../lib/utils';
import { useNavigate } from 'react-router-dom';
import { chatService } from '../services/chatService';
import { auth } from '../lib/firebase';
import { onAuthStateChanged } from 'firebase/auth';
import { Chat, Message } from '../types';

export const ChatListScreen = () => {
  const [selectedChat, setSelectedChat] = useState<Chat | null>(null);
  const [chatsList, setChatsList] = useState<Chat[]>([]);
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [user, setUser] = useState(auth.currentUser);
  const navigate = useNavigate();

  useEffect(() => {
    const unsubAuth = onAuthStateChanged(auth, (u) => setUser(u));
    
    // Subscribe to chat list
    const unsubChats = chatService.subscribeToChats((newChats) => {
      setChatsList(newChats);
      if (!selectedChat && newChats.length > 0) {
        setSelectedChat(newChats[0]);
      }
    });

    return () => {
      unsubAuth();
      unsubChats?.();
    };
  }, []);

  // Handle message sending
  const handleSendMessage = async () => {
    if (!newMessage.trim() || !selectedChat) return;
    await chatService.sendMessage(selectedChat.id, newMessage);
    setNewMessage('');
  };

  // Subscribe to messages when a chat is selected
  useEffect(() => {
    if (!selectedChat) return;
    const unsubMessages = chatService.subscribeToMessages(selectedChat.id, (msgs) => {
      setMessages(msgs);
    });
    return () => unsubMessages();
  }, [selectedChat]);

  return (
    <div className="flex h-screen overflow-hidden bg-surface">
      <Sidebar />
      
      <main className="flex-1 flex overflow-hidden relative">
        {/* Middle Column: Chat List */}
        <section className="w-full lg:w-96 flex flex-col bg-surface-container-low/30 border-r border-outline/10 overflow-hidden">
          <header className="p-8 pb-4">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-extrabold font-headline tracking-tight">Messages</h2>
              <div className="flex items-center gap-2">
                 <button className="w-10 h-10 flex items-center justify-center rounded-2xl bg-surface-container hover:bg-surface-container-high transition-colors">
                    <Filter className="text-outline w-5 h-5" />
                 </button>
                 <button className="w-10 h-10 flex items-center justify-center rounded-2xl bg-primary/10 text-primary hover:bg-primary/20 transition-colors">
                    <Edit3 className="w-5 h-5" />
                 </button>
              </div>
            </div>
            
            <div className="relative group">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-outline w-5 h-5 group-focus-within:text-primary transition-colors" />
              <input 
                type="text" 
                placeholder="Search conversations"
                className="w-full bg-surface-container-lowest border-none rounded-full py-4 pl-12 pr-4 text-sm focus:ring-4 focus:ring-primary/10 transition-all font-medium outline-none"
              />
            </div>
          </header>

          <div className="flex-1 overflow-y-auto px-4 space-y-1 no-scrollbar pb-24 lg:pb-8">
            {/* Stories Bar (Mobile only) */}
            <div className="lg:hidden flex gap-4 overflow-x-auto no-scrollbar py-4 mb-4">
              <div className="flex flex-col items-center gap-2 flex-shrink-0">
                <div className="relative w-16 h-16 rounded-full p-0.5 bg-surface-container-high ring-2 ring-outline/10">
                  <img src={user?.photoURL || 'https://avatar.iran.liara.run/public/boy?username=kskreddy'} className="w-full h-full rounded-full object-cover grayscale" />
                  <div className="absolute bottom-0 right-0 bg-primary text-on-surface w-6 h-6 rounded-full flex items-center justify-center border-4 border-surface shadow-lg">
                    <span className="text-sm font-bold">+</span>
                  </div>
                </div>
                <span className="text-[11px] font-medium text-on-surface-variant">Your Story</span>
              </div>
              {/* Other stories will follow */}
            </div>

            {chatsList.map((chat) => (
              <button 
                key={chat.id}
                onClick={() => setSelectedChat(chat)}
                className={cn(
                  "w-full flex items-center gap-4 p-4 rounded-3xl transition-all duration-300",
                  selectedChat?.id === chat.id 
                    ? "bg-surface-container-lowest shadow-sm"
                    : "hover:bg-surface-container-lowest/50"
                )}
              >
                <div className="relative flex-shrink-0">
                  <img src={chat.avatar} alt={chat.name} className="w-14 h-14 rounded-2xl object-cover" />
                  {chat.online && (
                    <div className="absolute -bottom-1 -right-1 w-4 h-4 bg-secondary rounded-full border-4 border-surface shadow-lg" />
                  )}
                </div>
                <div className="flex-1 min-w-0 text-left">
                  <div className="flex justify-between items-baseline mb-0.5">
                    <h4 className="font-headline font-bold text-on-surface truncate">{chat.name}</h4>
                    <span className="text-[10px] font-bold text-outline uppercase tracking-wider">{chat.time}</span>
                  </div>
                  <p className={cn(
                    "text-sm truncate leading-none pt-1",
                    chat.unread ? "text-on-surface font-bold" : "text-outline font-medium"
                  )}>
                    {chat.type === 'typing' ? (
                      <span className="text-primary italic animate-pulse flex items-center gap-1">
                         <span className="w-1 h-1 rounded-full bg-primary animate-bounce [animation-delay:-0.3s]" />
                         <span className="w-1 h-1 rounded-full bg-primary animate-bounce [animation-delay:-0.15s]" />
                         <span className="w-1 h-1 rounded-full bg-primary animate-bounce" />
                         Typing...
                      </span>
                    ) : chat.lastMessage}
                  </p>
                </div>
                {chat.unreadCount > 0 && (
                  <div className="w-6 h-6 bg-primary text-on-surface rounded-full flex items-center justify-center text-[10px] font-bold ring-4 ring-primary/10">
                    {chat.unreadCount}
                  </div>
                )}
              </button>
            ))}
          </div>
        </section>

        {/* Right Column: Chat Window */}
        <section className="hidden md:flex flex-1 flex-col bg-surface overflow-hidden relative">
          <header className="h-24 px-8 border-b border-outline/10 flex items-center justify-between glass-header z-20">
             <div className="flex items-center gap-4">
                <div className="relative">
                  <img src={selectedChat?.avatar || 'https://avatar.iran.liara.run/public/boy?username=' + (selectedChat?.name || 'user')} className="w-12 h-12 rounded-2xl object-cover" />
                  {selectedChat?.online && <div className="absolute -bottom-1 -right-1 w-3.5 h-3.5 bg-secondary rounded-full border-[3px] border-surface shadow-lg" />}
                </div>
                <div>
                   <h3 className="text-lg font-extrabold font-headline tracking-tight">{selectedChat?.name || 'Select a Chat'}</h3>
                   <p className="text-xs font-semibold text-secondary flex items-center gap-1.5 leading-none">
                      <span className="w-1.5 h-1.5 rounded-full bg-secondary animate-pulse" />
                      Active Now
                   </p>
                </div>
             </div>
             <div className="flex items-center gap-3">
                <button 
                  onClick={() => navigate('/call')}
                  className="w-12 h-12 flex items-center justify-center rounded-2xl bg-surface-container hover:bg-surface-container-high transition-colors"
                >
                  <Phone className="w-5 h-5 text-outline" />
                </button>
                <button className="w-12 h-12 flex items-center justify-center rounded-2xl bg-surface-container hover:bg-surface-container-high transition-colors">
                  <Video className="w-5 h-5 text-outline" />
                </button>
                <button className="w-12 h-12 flex items-center justify-center rounded-2xl bg-primary-container text-primary hover:brightness-95 transition-all">
                  <Info className="w-5 h-5" />
                </button>
             </div>
          </header>

          <div className="flex-1 overflow-y-auto p-10 space-y-8 no-scrollbar bg-surface/50 pattern-bg relative">
             <div className="flex justify-center sticky top-0 z-10 pointer-events-none">
                <motion.div 
                  initial={{ y: -20, opacity: 0 }}
                  animate={{ y: 0, opacity: 1 }}
                  className="bg-primary/5 text-primary text-[10px] font-bold px-6 py-2.5 rounded-full flex items-center gap-2 ring-1 ring-primary/20 backdrop-blur-2xl shadow-xl pointer-events-auto cursor-pointer hover:bg-primary/10 transition-colors uppercase tracking-widest"
                >
                   <Sparkles className="w-3.5 h-3.5 animate-pulse" />
                   AI SUMMARY: PLANNING THE DESIGN SPRINT
                </motion.div>
             </div>
             
             {/* Dynamic Message Bubbles */}
             <div className="flex flex-col gap-6">
                {messages.map((msg) => (
                   <div 
                     key={msg.messageId} 
                     className={cn(
                       "flex items-end gap-3",
                       msg.senderId === user?.uid ? "justify-end" : "justify-start"
                     )}
                   >
                      {msg.senderId !== user?.uid && (
                        <img src={selectedChat?.avatar} className="w-8 h-8 rounded-xl object-cover" />
                      )}
                      <div className={cn(
                        "p-5 rounded-3xl text-sm max-w-[70%] shadow-sm leading-relaxed font-medium",
                        msg.senderId === user?.uid 
                          ? "bg-primary text-on-surface rounded-br-none shadow-lg shadow-primary/20 font-bold" 
                          : "bg-surface-container-lowest text-on-surface rounded-bl-none border border-outline/5"
                      )}>
                         {msg.text}
                      </div>
                      {msg.senderId === user?.uid && (
                        <img src={user?.photoURL || 'https://avatar.iran.liara.run/public/boy?username=kskreddy'} className="w-8 h-8 rounded-xl object-cover" />
                      )}
                   </div>
                ))}

                <div className="flex items-center gap-4 my-8">
                   <div className="flex-1 h-px bg-outline/10" />
                   <span className="text-[10px] font-bold text-outline uppercase tracking-widest">Today, 11:24 AM</span>
                   <div className="flex-1 h-px bg-outline/10" />
                </div>
             </div>
          </div>

          <footer className="p-8 pt-4">
             <div className="flex items-end gap-4 bg-surface-container-low p-2 pr-4 rounded-[2.5rem] ring-1 ring-outline/10 shadow-2xl">
                <button className="w-12 h-12 flex items-center justify-center rounded-full text-outline hover:bg-surface-container-high transition-colors">
                  <Paperclip className="w-5 h-5" />
                </button>
                <textarea 
                  placeholder="Type a message..."
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && (e.preventDefault(), handleSendMessage())}
                  className="flex-1 bg-transparent border-none py-3 px-2 focus:ring-0 text-sm font-medium h-12 resize-none outline-none leading-relaxed"
                />
                <div className="flex items-center gap-1 mb-1">
                   <button className="w-10 h-10 flex items-center justify-center rounded-full text-outline hover:bg-surface-container">
                     <Smile className="w-5 h-5" />
                   </button>
                   <button className="w-10 h-10 flex items-center justify-center rounded-full text-outline hover:bg-surface-container">
                     <Mic className="w-5 h-5" />
                   </button>
                   <button 
                     onClick={handleSendMessage}
                     disabled={!newMessage.trim()}
                     className="w-12 h-12 flex items-center justify-center rounded-full bg-primary text-on-surface shadow-xl shadow-primary/30 hover:brightness-110 active:scale-95 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                   >
                     <Send className="w-5 h-5" />
                   </button>
                </div>
             </div>
          </footer>
        </section>
      </main>

      <BottomNav />
      {/* Background Noise Texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.03] z-[100] bg-[url('https://www.transparenttextures.com/patterns/cubes.png')]" />
    </div>
  );
};
