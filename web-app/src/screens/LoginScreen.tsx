import React, { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { ArrowRight, Phone, ChevronRight, MessageSquare } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { authService } from '../services/authService';

export const LoginScreen = () => {
  const [phoneNumber, setPhoneNumber] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    authService.setupRecaptcha('recaptcha-container');
  }, []);

  const handleSendOTP = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!phoneNumber) return;
    
    setIsLoading(true);
    try {
      const confirmationResult = await authService.sendOTP(phoneNumber);
      navigate('/otp', { state: { confirmationResult, phoneNumber } });
    } catch (error: any) {
      alert(error.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center relative overflow-hidden px-8 bg-surface">
      {/* Ambient Background */}
      <div className="absolute top-0 left-0 w-full h-full z-0 opacity-20 pointer-events-none">
        <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-primary/30 blur-[120px] rounded-full animate-pulse" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-secondary/20 blur-[120px] rounded-full animate-pulse delay-700" />
      </div>

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-md bg-surface-container-lowest/50 backdrop-blur-3xl p-12 rounded-[3.5rem] border border-outline/10 shadow-2xl relative z-10"
      >
        <header className="text-center mb-12">
          <div className="w-20 h-20 bg-primary/10 rounded-3xl flex items-center justify-center mx-auto mb-6 ring-1 ring-primary/20 shadow-inner">
             <MessageSquare className="w-10 h-10 text-primary" />
          </div>
          <h1 className="text-4xl font-extrabold font-headline tracking-tighter text-on-surface mb-2">Welcome to Sambhasha</h1>
          <p className="text-outline font-medium tracking-wide">Enter your mobile number to get started</p>
        </header>

        <section className="flex flex-col gap-8">
          <form onSubmit={handleSendOTP} className="space-y-6">
            <div className="relative group">
              <Phone className="absolute left-6 top-1/2 -translate-y-1/2 text-outline group-focus-within:text-primary transition-colors w-5 h-5" />
              <input 
                type="tel" 
                placeholder="+1 123 456 7890"
                value={phoneNumber}
                onChange={(e) => setPhoneNumber(e.target.value)}
                className="w-full bg-surface-container border-none rounded-[2rem] py-6 pl-16 pr-6 text-lg focus:ring-4 focus:ring-primary/10 transition-all font-medium outline-none placeholder:text-outline/40"
              />
            </div>

            <button 
              type="submit"
              disabled={isLoading || !phoneNumber}
              className="w-full bg-primary text-on-surface py-6 rounded-[2rem] font-headline font-extrabold text-xl flex items-center justify-center gap-3 shadow-2xl shadow-primary/30 hover:brightness-110 active:scale-95 transition-all disabled:opacity-50"
            >
              {isLoading ? 'Sending...' : 'Continue'}
              <ChevronRight className="w-6 h-6" />
            </button>
          </form>

          <div id="recaptcha-container"></div>
            
          <p className="text-center text-xs text-outline leading-relaxed px-4">
            By continuing, you agree to Sambhasha's 
            <span className="text-primary font-bold mx-1 cursor-pointer hover:underline">Terms of Service</span> 
            and 
            <span className="text-primary font-bold mx-1 cursor-pointer hover:underline">Privacy Policy</span>.
          </p>
        </section>
      </motion.div>
      
      {/* Background Noise Texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.03] z-[100] bg-[url('https://www.transparenttextures.com/patterns/cubes.png')]" />
    </div>
  );
};
