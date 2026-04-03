import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { 
  MessageSquare, Phone, MapPin, Settings, Plus, LayoutGrid, 
  Search, Ampersands, Info 
} from 'lucide-react';
import { currentUser } from '../constants';
import { cn } from '../lib/utils';

export const Sidebar = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const currentPath = location.pathname;

  const navItems = [
    { icon: LayoutGrid, label: 'Dashboard', path: '/dashboard' },
    { icon: MessageSquare, label: 'Messages', path: '/chats' },
    { icon: Phone, label: 'Calls', path: '/calls' },
    { icon: Ampersands, label: 'Stories', path: '/stories' },
    { icon: Settings, label: 'Settings', path: '/settings' },
  ];

  return (
    <aside className="hidden lg:flex w-80 flex-col bg-surface-container-lowest border-r border-outline-variant/10 p-8">
      <div className="flex items-center gap-3 mb-12 px-2">
        <div className="w-10 h-10 bg-primary rounded-2xl flex items-center justify-center shadow-lg shadow-primary/20">
          <MessageSquare className="text-on-primary w-6 h-6 fill-current" />
        </div>
        <h1 className="text-2xl font-extrabold font-headline tracking-tighter text-on-surface">Sambhasha</h1>
      </div>

      <nav className="flex-1 space-y-2">
        {navItems.map((item) => (
          <button
            key={item.label}
            onClick={() => navigate(item.path)}
            className={cn(
              "w-full flex items-center gap-4 px-4 py-3 rounded-xl transition-all duration-200 font-headline font-semibold text-sm relative",
              currentPath === item.path
                ? "text-primary bg-surface-container-low"
                : "text-outline hover:bg-surface-container-low"
            )}
          >
            <item.icon className="w-5 h-5" />
            <span>{item.label}</span>
          </button>
        ))}
      </nav>

      <div className="mt-auto space-y-6">
        <button className="w-full bg-gradient-to-br from-primary to-primary-dim text-on-primary py-4 px-6 rounded-2xl shadow-xl shadow-primary/20 font-bold flex items-center justify-center gap-3 active:scale-95 transition-all">
          <Plus className="w-5 h-5" />
          <span>New Message</span>
        </button>

        <div className="flex items-center gap-3 px-2">
          <img src={currentUser.avatar} alt={currentUser.name} className="w-10 h-10 rounded-full object-cover" />
          <div className="overflow-hidden">
            <p className="text-sm font-semibold truncate">{currentUser.name}</p>
            <p className="text-xs text-outline truncate">{currentUser.email}</p>
          </div>
        </div>
      </div>
    </aside>
  );
};

export const BottomNav = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const currentPath = location.pathname;

  const navItems = [
    { icon: MessageSquare, label: 'Chats', path: '/chats' },
    { icon: Phone, label: 'Calls', path: '/calls' },
    { icon: Ampersands, label: 'Stories', path: '/stories' },
    { icon: Settings, label: 'Settings', path: '/settings' },
  ];

  return (
    <nav className="lg:hidden fixed bottom-0 left-0 right-0 h-24 bg-surface/80 backdrop-blur-2xl border-t border-outline-variant/10 px-8 flex items-center justify-between z-50">
      {navItems.map((item) => (
        <button
          key={item.label}
          onClick={() => navigate(item.path)}
          className={cn(
            "flex flex-col items-center gap-1 p-2 rounded-2xl transition-all",
            currentPath === item.path ? "text-primary scale-110" : "text-outline"
          )}
        >
          <item.icon className="w-6 h-6" />
          <span className="text-[10px] font-bold uppercase tracking-widest">{item.label}</span>
        </button>
      ))}
    </nav>
  );
};
