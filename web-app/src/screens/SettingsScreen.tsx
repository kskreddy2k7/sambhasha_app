import React from 'react';
import { motion } from 'motion/react';
import { 
  User, Bell, Shield, Database, HelpCircle, LogOut, 
  ChevronRight, Camera, Moon, Globe, MessageSquare, Search 
} from 'lucide-react';
import { Sidebar, BottomNav } from '../components/Navigation';
import { currentUser } from '../constants';
import { useNavigate } from 'react-router-dom';

export const SettingsScreen = () => {
  const navigate = useNavigate();

  const settingsGroups = [
    {
      title: 'Common',
      items: [
        { icon: User, label: 'Account', color: 'bg-primary/20 text-primary', detail: 'Privacy, security, change number' },
        { icon: MessageSquare, label: 'Chats', color: 'bg-secondary/20 text-secondary', detail: 'Theme, wallpapers, chat history' },
        { icon: Bell, label: 'Notifications', color: 'bg-orange-500/20 text-orange-500', detail: 'Message, group & call tones' },
      ]
    },
    {
      title: 'System',
      items: [
        { icon: Database, label: 'Storage and Data', color: 'bg-green-500/20 text-green-500', detail: 'Network usage, auto-download' },
        { icon: Shield, label: 'Privacy', color: 'bg-indigo-500/20 text-indigo-500', detail: 'Last seen, profile photo, status' },
        { icon: Globe, label: 'App Language', color: 'bg-teal-500/20 text-teal-500', detail: "English (phone's language)" },
      ]
    },
  ];

  return (
    <div className="flex h-screen overflow-hidden bg-surface">
      <Sidebar />
      
      <main className="flex-1 flex flex-col overflow-hidden relative">
        <header className="p-10 pb-6 flex items-center justify-between z-10">
          <h2 className="text-4xl font-extrabold font-headline tracking-tighter text-on-surface">Settings</h2>
          <button className="lg:hidden w-12 h-12 flex items-center justify-center rounded-2xl bg-surface-container hover:bg-surface-container-high transition-colors">
             <Search className="w-5 h-5 text-outline" />
          </button>
        </header>

        <div className="flex-1 overflow-y-auto px-10 pb-32 lg:pb-12 space-y-10 no-scrollbar">
          {/* Profile Card */}
          <section className="bg-surface-container-low rounded-[3rem] p-10 flex flex-col md:flex-row items-center gap-10 border border-outline/5 shadow-2xl relative overflow-hidden group">
             <div className="absolute top-0 right-0 w-64 h-64 bg-primary/5 blur-[100px] -mr-32 -mt-32 transition-transform duration-700 group-hover:scale-150" />
             <div className="relative">
                <div className="w-40 h-40 rounded-[2.5rem] p-1 bg-gradient-to-br from-primary to-secondary shadow-2xl relative overflow-hidden ring-4 ring-surface">
                   <img src={currentUser.avatar} className="w-full h-full rounded-[2.3rem] object-cover" alt={currentUser.name} />
                </div>
                <button className="absolute -bottom-2 -right-2 w-12 h-12 bg-primary text-on-surface rounded-2xl flex items-center justify-center border-4 border-surface shadow-xl hover:scale-110 transition-all">
                   <Camera className="w-6 h-6" />
                </button>
             </div>
             
             <div className="flex-1 text-center md:text-left space-y-2">
                <h3 className="font-headline font-extrabold text-4xl text-on-surface tracking-tight leading-none">{currentUser.name}</h3>
                <p className="text-lg font-bold text-outline leading-tight">{currentUser.email}</p>
                <div className="bg-primary/10 text-primary text-[10px] font-extrabold px-4 py-1.5 rounded-full inline-block mt-4 uppercase tracking-[0.2em] ring-1 ring-primary/20">
                   Sambhasha Elite Member
                </div>
             </div>

             <button className="w-full md:w-auto px-10 py-5 bg-surface-container-lowest text-on-surface text-sm font-bold rounded-2xl hover:bg-surface-container-high transition-all shadow-xl active:scale-95 border border-outline/5">
                Edit Profile
             </button>
          </section>

          {/* Settings List */}
          <div className="grid grid-cols-1 xl:grid-cols-2 gap-10">
             {settingsGroups.map((group) => (
                <div key={group.title} className="space-y-6">
                   <h4 className="text-[10px] font-extrabold text-primary uppercase tracking-[0.3em] pl-2 leading-none">{group.title}</h4>
                   <div className="bg-surface-container-lowest/50 rounded-[3rem] border border-outline/5 overflow-hidden shadow-sm">
                      {group.items.map((item, i) => (
                         <button 
                            key={item.label}
                            className={`w-full flex items-center gap-6 p-8 hover:bg-surface-container transition-all text-left ${i !== group.items.length - 1 ? 'border-b border-outline/5' : ''}`}
                         >
                            <div className={`w-14 h-14 rounded-2xl ${item.color} flex items-center justify-center shadow-lg`}>
                               <item.icon className="w-6 h-6" />
                            </div>
                            <div className="flex-1">
                               <p className="font-headline font-extrabold text-lg text-on-surface tracking-tight leading-none mb-1">{item.label}</p>
                               <p className="text-xs font-bold text-outline leading-tight tracking-wide">{item.detail}</p>
                            </div>
                            <ChevronRight className="w-5 h-5 text-outline/30 group-hover:text-primary transition-colors" />
                         </button>
                      ))}
                   </div>
                </div>
             ))}
          </div>

          <button 
            onClick={() => navigate('/')}
            className="w-full max-w-sm mx-auto flex items-center justify-center gap-4 py-8 rounded-[2.5rem] bg-error-container/10 text-error-container font-headline font-extrabold text-xl hover:bg-error-container/20 transition-all border border-error-container/20 shadow-xl shadow-error-container/5 active:scale-95 mb-10"
          >
             <LogOut className="w-6 h-6" />
             Log Out
          </button>
        </div>
      </main>

      <BottomNav />
      {/* Background Noise Texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.03] z-[100] bg-[url('https://www.transparenttextures.com/patterns/cubes.png')]" />
    </div>
  );
};
