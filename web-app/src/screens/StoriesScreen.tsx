import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { X, ChevronLeft, ChevronRight, MapPin, Send, MessageCircle } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { users } from '../constants';

export const StoriesScreen = () => {
  const navigate = useNavigate();
  const [currentStoryIndex, setCurrentStoryIndex] = useState(0);
  const [progress, setProgress] = useState(0);

  const stories = [
    {
      id: 's1',
      user: users[0],
      image: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&q=80&w=1000',
      location: 'San Francisco, CA'
    },
    {
      id: 's2',
      user: users[1],
      image: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&q=80&w=1000',
      location: 'New York City, NY'
    },
    {
      id: 's3',
      user: users[2],
      image: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?auto=format&fit=crop&q=80&w=1000',
      location: 'Berlin, Germany'
    }
  ];

  useEffect(() => {
    const timer = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          if (currentStoryIndex < stories.length - 1) {
            setCurrentStoryIndex(currentStoryIndex + 1);
            return 0;
          } else {
            navigate('/chats');
            return 100;
          }
        }
        return prev + 1;
      });
    }, 50);

    return () => clearInterval(timer);
  }, [currentStoryIndex, navigate, stories.length]);

  const currentStory = stories[currentStoryIndex];

  return (
    <div className="bg-black h-screen overflow-hidden relative flex items-center justify-center">
      {/* Background Image (Blurred) */}
      <div className="absolute inset-0 z-0">
        <img 
          src={currentStory.image} 
          className="w-full h-full object-cover blur-[120px] scale-150 opacity-40 shadow-2xl shadow-primary/20" 
          alt="" 
        />
        <div className="absolute inset-0 bg-gradient-to-b from-black/60 via-transparent to-black/80" />
      </div>

      <div className="relative z-10 w-full max-w-lg h-full sm:h-[90vh] sm:rounded-[3rem] overflow-hidden shadow-2xl bg-surface-container-lowest ring-1 ring-white/10">
        {/* Progress Bars */}
        <div className="absolute top-0 left-0 right-0 p-6 flex gap-2 z-30">
          {stories.map((_, i) => (
            <div key={i} className="h-1 flex-1 bg-white/20 rounded-full overflow-hidden">
              <div 
                className="h-full bg-primary shadow-lg shadow-primary/40 rounded-full transition-all duration-100 ease-linear"
                style={{ 
                  width: i < currentStoryIndex ? '100%' : i === currentStoryIndex ? `${progress}%` : '0%' 
                }}
              />
            </div>
          ))}
        </div>

        {/* Header */}
        <header className="absolute top-10 left-0 right-0 px-6 flex items-center justify-between z-30">
          <div className="flex items-center gap-3">
             <div className="w-12 h-12 rounded-2xl p-[3px] ring-2 ring-primary shadow-xl">
                <img src={currentStory.user.avatar} className="w-full h-full rounded-2xl object-cover" />
             </div>
             <div>
                <h3 className="text-sm font-extrabold font-headline text-white tracking-widest uppercase">{currentStory.user.name}</h3>
                <p className="text-[10px] font-bold text-outline uppercase tracking-wider flex items-center gap-1 leading-none mt-1">
                   <MapPin className="w-3 h-3 text-secondary" />
                   {currentStory.location}
                </p>
             </div>
          </div>
          <button 
            onClick={() => navigate('/chats')}
            className="w-12 h-12 flex items-center justify-center rounded-full bg-white/10 backdrop-blur-3xl hover:bg-white/20 transition-all text-white active:scale-95 shadow-lg border border-white/5"
          >
            <X className="w-6 h-6" />
          </button>
        </header>

        <AnimatePresence mode="wait">
          <motion.div
            key={currentStoryIndex}
            initial={{ scale: 0.95, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 1.05, opacity: 0 }}
            className="h-full w-full relative"
          >
            <img 
              src={currentStory.image} 
              className="w-full h-full object-cover" 
              alt="Story" 
            />
            {/* Story Content Overlay */}
            <div className="absolute bottom-32 left-8 max-w-[80%]">
               <motion.div 
                 initial={{ y: 20, opacity: 0 }}
                 animate={{ y: 0, opacity: 1 }}
                 transition={{ delay: 0.3 }}
                 className="bg-primary/20 backdrop-blur-3xl p-5 rounded-3xl border border-white/10 shadow-2xl"
               >
                  <p className="text-white font-headline font-bold text-xl leading-relaxed tracking-tight">
                    "Pushing the boundaries of decentralized messaging with Sambhasha. 🚀 #web3"
                  </p>
               </motion.div>
            </div>
          </motion.div>
        </AnimatePresence>

        {/* Navigation Areas */}
        <div className="absolute inset-x-0 inset-y-24 flex z-20">
          <div 
            className="flex-1 cursor-pointer" 
            onClick={() => currentStoryIndex > 0 && (setCurrentStoryIndex(currentStoryIndex - 1), setProgress(0))}
          />
          <div 
            className="flex-1 cursor-pointer" 
            onClick={() => currentStoryIndex < stories.length - 1 ? (setCurrentStoryIndex(currentStoryIndex + 1), setProgress(0)) : navigate('/chats')}
          />
        </div>

        {/* Footer */}
        <footer className="absolute bottom-0 left-0 right-0 p-8 pt-4 bg-gradient-to-t from-black/80 to-transparent z-30">
          <div className="flex items-center gap-4">
             <div className="flex-1 bg-white/10 backdrop-blur-3xl border border-white/10 rounded-full px-6 py-4 flex items-center shadow-2xl ring-1 ring-white/5">
                <input 
                  type="text" 
                  placeholder="Send a message..." 
                  className="bg-transparent border-none w-full text-white text-sm font-semibold focus:ring-0 outline-none"
                />
             </div>
             <button className="w-14 h-14 rounded-full bg-primary flex items-center justify-center text-on-surface shadow-2xl shadow-primary/40 hover:brightness-110 active:scale-95 transition-all">
                <Send className="w-6 h-6" />
             </button>
             <button className="w-14 h-14 rounded-full bg-white/10 backdrop-blur-3xl flex items-center justify-center text-white border border-white/10 shadow-2xl active:scale-95 transition-all">
                <MessageCircle className="w-6 h-6" />
             </button>
          </div>
        </footer>
      </div>
    </div>
  );
};
