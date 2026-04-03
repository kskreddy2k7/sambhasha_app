import React from 'react';
import { motion } from 'motion/react';
import { ChevronDown, UserPlus, MicOff, Volume2, Video, PhoneOff, Sparkles } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { users } from '../constants';

export const ActiveCallScreen = () => {
  const navigate = useNavigate();
  const caller = users[1]; // Julian Chen

  return (
    <div className="bg-surface font-sans text-on-surface antialiased overflow-hidden h-screen relative">
      {/* Background Canvas: Blurred Feed */}
      <div className="fixed inset-0 z-0">
        <img 
          src={caller.avatar} 
          className="w-full h-full object-cover scale-150 blur-[100px] opacity-30" 
          alt="" 
        />
        <div className="absolute inset-0 bg-gradient-to-b from-surface/40 via-transparent to-surface/90" />
      </div>

      {/* Active Call UI Shell */}
      <div className="relative z-10 flex flex-col h-full w-full max-w-md mx-auto">
        <header className="flex justify-between items-center px-8 h-24 w-full pt-4">
          <button 
            onClick={() => navigate(-1)}
            className="w-12 h-12 flex items-center justify-center rounded-2xl bg-surface-container-low backdrop-blur-3xl hover:bg-surface-container-high transition-colors shadow-lg border border-outline/10"
          >
            <ChevronDown className="w-6 h-6" />
          </button>
          
          <div className="flex flex-col items-center">
             <span className="font-headline font-extrabold text-on-surface text-xl tracking-tight uppercase">Sambhasha</span>
             <div className="flex items-center gap-1.5 leading-none">
                <span className="w-1.5 h-1.5 rounded-full bg-secondary animate-pulse" />
                <span className="font-sans text-[10px] font-bold uppercase tracking-widest text-on-surface-variant">Encrypted</span>
             </div>
          </div>

          <button className="w-12 h-12 flex items-center justify-center rounded-2xl bg-surface-container-low backdrop-blur-3xl hover:bg-surface-container-high transition-colors shadow-lg border border-outline/10">
            <UserPlus className="w-5 h-5 text-outline" />
          </button>
        </header>

        <main className="flex-1 flex flex-col items-center justify-center px-6 -mt-20">
          <div className="relative mb-12">
            {/* Animated Rings */}
            <div className="absolute inset-0 -m-8 rounded-full border border-primary/20 scale-125 animate-ping opacity-20" />
            <div className="absolute inset-0 -m-4 rounded-full border border-primary/10 scale-110 opacity-40" />
            
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              className="w-56 h-56 rounded-full overflow-hidden border-8 border-surface-container-low shadow-2xl relative ring-4 ring-primary/20"
            >
              <img src={caller.avatar} className="w-full h-full object-cover" alt={caller.name} />
            </motion.div>
            
            {/* Video Mini-Preview (Self) */}
            <motion.div
              initial={{ x: 20, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: 0.3 }}
              className="absolute bottom-2 right-2 w-20 h-28 rounded-2xl overflow-hidden border-4 border-surface shadow-2xl shadow-black/40 ring-1 ring-outline/10"
            >
              <img 
                src="https://avatar.iran.liara.run/public/boy?username=kskreddy" 
                className="w-full h-full object-cover grayscale brightness-75" 
                alt="Self" 
              />
            </motion.div>
          </div>

          <div className="text-center space-y-4">
            <h1 className="font-headline font-extrabold text-5xl text-on-surface tracking-tighter leading-none">{caller.name}</h1>
            <p className="font-sans text-xl font-bold text-primary tracking-widest tabular-nums animate-pulse">00:42</p>
          </div>
        </main>

        <footer className="pb-16 px-8 space-y-8">
          {/* Transcription Card */}
          <motion.div
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.5 }}
            className="p-6 rounded-[2.5rem] bg-surface-container-lowest backdrop-blur-3xl border border-outline/10 shadow-2xl flex items-start gap-5 ring-1 ring-primary/10"
          >
             <div className="p-3 rounded-2xl bg-primary text-on-surface shadow-lg shadow-primary/30">
                <Sparkles className="w-5 h-5 fill-current" />
             </div>
             <div className="flex-1 space-y-1">
                <span className="text-[10px] font-extrabold text-primary uppercase tracking-[0.2em] leading-none mb-1 block">Live AI Transcription</span>
                <p className="text-sm font-bold text-on-surface-variant leading-relaxed">
                   "So I was thinking we could follow up on the tone-and-voice guidelines we established in the last sprint..."
                </p>
             </div>
          </motion.div>

          {/* Call Controls */}
          <div className="flex justify-between items-center bg-surface-container-low/80 backdrop-blur-3xl p-5 rounded-[3rem] border border-outline/10 ring-8 ring-surface-container-lowest/50 shadow-2xl">
             <button className="w-16 h-16 rounded-full flex items-center justify-center bg-surface-container text-on-surface-variant hover:bg-primary/20 hover:text-primary transition-all active:scale-95 shadow-lg">
                <MicOff className="w-7 h-7" />
             </button>
             <button className="w-16 h-16 rounded-full flex items-center justify-center bg-surface-container text-on-surface-variant hover:bg-primary/20 hover:text-primary transition-all active:scale-95 shadow-lg">
                <Volume2 className="w-7 h-7" />
             </button>
             <button className="w-16 h-16 rounded-full flex items-center justify-center bg-surface-container text-on-surface-variant hover:bg-primary/20 hover:text-primary transition-all active:scale-95 shadow-lg">
                <Video className="w-7 h-7" />
             </button>
             <button 
                onClick={() => navigate(-1)}
                className="w-18 h-18 rounded-full flex items-center justify-center bg-primary text-on-surface shadow-2xl shadow-primary/40 hover:brightness-110 active:scale-95 transition-all"
              >
                <PhoneOff className="w-8 h-8 fill-current" />
             </button>
          </div>
        </footer>
      </div>
      
      {/* Background Noise Texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.03] z-[100] bg-[url('https://www.transparenttextures.com/patterns/cubes.png')]" />
    </div>
  );
};
