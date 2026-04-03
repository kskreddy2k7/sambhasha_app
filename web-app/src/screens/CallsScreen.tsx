import React from 'react';
import { motion } from 'motion/react';
import { Phone, PhoneOutgoing, PhoneIncoming, MessageSquare, Plus, Search, Filter } from 'lucide-react';
import { Sidebar, BottomNav } from '../components/Navigation';
import { users } from '../constants';
import { useNavigate } from 'react-router-dom';

export const CallsScreen = () => {
  const navigate = useNavigate();

  const callHistory = [
    { user: users[1], type: 'outgoing', time: 'Yesterday, 10:45 PM', duration: '12:45' },
    { user: users[0], type: 'incoming', time: 'Monday, 09:12 AM', duration: 'Missed' },
    { user: users[2], type: 'outgoing', time: 'Sunday, 11:30 PM', duration: '45:10' },
  ];

  return (
    <div className="flex h-screen overflow-hidden bg-surface">
      <Sidebar />
      
      <main className="flex-1 flex flex-col overflow-hidden relative">
        <header className="p-10 pb-6 flex items-center justify-between z-10">
          <h2 className="text-4xl font-extrabold font-headline tracking-tighter text-on-surface">Calls</h2>
          <div className="flex items-center gap-3">
             <button className="w-12 h-12 flex items-center justify-center rounded-2xl bg-surface-container hover:bg-surface-container-high transition-colors text-outline">
                <Search className="w-5 h-5" />
             </button>
             <button className="w-12 h-12 flex items-center justify-center rounded-2xl bg-primary text-on-surface shadow-xl shadow-primary/30 hover:brightness-110 active:scale-95 transition-all">
                <Plus className="w-6 h-6" />
             </button>
          </div>
        </header>

        <div className="flex-1 overflow-y-auto px-10 pb-32 lg:pb-12 space-y-6 no-scrollbar">
           <div className="bg-surface-container-low rounded-[2.5rem] border border-outline/5 overflow-hidden shadow-2xl">
              {callHistory.map((call, i) => (
                 <div 
                   key={i}
                   className={`flex items-center gap-6 p-8 hover:bg-surface-container transition-all cursor-pointer ${i !== callHistory.length - 1 ? 'border-b border-outline/5' : ''}`}
                   onClick={() => navigate('/call')}
                 >
                    <div className="relative">
                       <img src={call.user.avatar} className="w-14 h-14 rounded-2xl object-cover ring-2 ring-outline/10" alt={call.user.name} />
                       <div className={`absolute -bottom-1 -right-1 w-6 h-6 rounded-full flex items-center justify-center border-4 border-surface ${call.duration === 'Missed' ? 'bg-error-container text-on-error-container' : 'bg-primary text-on-surface'}`}>
                          {call.type === 'outgoing' ? <PhoneOutgoing className="w-3 h-3" /> : <PhoneIncoming className="w-3 h-3" />}
                       </div>
                    </div>
                    
                    <div className="flex-1">
                       <h3 className="font-headline font-extrabold text-xl text-on-surface tracking-tight leading-none mb-1">{call.user.name}</h3>
                       <p className="text-xs font-bold text-outline uppercase tracking-widest">{call.time}</p>
                    </div>

                    <div className="text-right">
                       <p className={`text-sm font-extrabold font-headline ${call.duration === 'Missed' ? 'text-error-container' : 'text-primary'}`}>
                          {call.duration}
                       </p>
                       <div className="flex items-center gap-3 mt-2">
                          <button className="w-10 h-10 flex items-center justify-center rounded-full bg-surface-container-low text-outline hover:bg-primary/20 hover:text-primary transition-all">
                             <MessageSquare className="w-4 h-4" />
                          </button>
                          <button className="w-10 h-10 flex items-center justify-center rounded-full bg-surface-container-low text-outline hover:bg-primary/20 hover:text-primary transition-all">
                             <Phone className="w-4 h-4" />
                          </button>
                       </div>
                    </div>
                 </div>
              ))}
           </div>
        </div>
      </main>

      <BottomNav />
      {/* Background Noise Texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.03] z-[100] bg-[url('https://www.transparenttextures.com/patterns/cubes.png')]" />
    </div>
  );
};
