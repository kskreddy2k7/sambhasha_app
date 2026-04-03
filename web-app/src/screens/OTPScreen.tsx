import React, { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { ArrowLeft, CheckCircle2, ChevronRight, MessageSquare } from 'lucide-react';
import { useNavigate, useLocation } from 'react-router-dom';
import { authService } from '../services/authService';

export const OTPScreen = () => {
  const [otp, setOtp] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  const { confirmationResult, phoneNumber } = location.state || {};

  useEffect(() => {
    if (!confirmationResult) {
      navigate('/');
    }
  }, [confirmationResult, navigate]);

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!otp || otp.length < 6) return;

    setIsLoading(true);
    try {
      await authService.verifyOTP(confirmationResult, otp);
      navigate('/chats');
    } catch (error: any) {
      alert(error.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center relative overflow-hidden px-8 bg-surface">
      {/* Ambient Background */}
      <div className="absolute top-0 right-0 w-full h-full z-0 opacity-20 pointer-events-none">
        <div className="absolute top-[-10%] right-[-10%] w-[40%] h-[40%] bg-primary/30 blur-[120px] rounded-full animate-pulse" />
        <div className="absolute bottom-[-10%] left-[-10%] w-[40%] h-[40%] bg-secondary/20 blur-[120px] rounded-full animate-pulse delay-700" />
      </div>

      <motion.div 
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="w-full max-w-md bg-surface-container-lowest/50 backdrop-blur-3xl p-12 rounded-[3.5rem] border border-outline/10 shadow-2xl relative z-10"
      >
        <header className="text-center mb-12">
          <button 
            onClick={() => navigate('/')}
            className="w-12 h-12 flex items-center justify-center rounded-2xl bg-surface-container hover:bg-surface-container-high transition-colors mb-8 mx-auto"
          >
            <ArrowLeft className="w-5 h-5 text-outline" />
          </button>
          <h1 className="text-4xl font-extrabold font-headline tracking-tighter text-on-surface mb-2">Verify Code</h1>
          <p className="text-outline font-medium tracking-wide">Enter the 6-digit code sent to <span className="text-primary">{phoneNumber}</span></p>
        </header>

        <section className="flex flex-col gap-8">
          <form onSubmit={handleVerify} className="space-y-8">
            <div className="flex justify-center">
              <input 
                type="text" 
                maxLength={6}
                value={otp}
                onChange={(e) => setOtp(e.target.value.replace(/\D/g, ''))}
                placeholder="000000"
                className="w-full bg-surface-container border-none rounded-3xl py-8 text-center text-5xl font-black tracking-[0.5em] focus:ring-8 focus:ring-primary/10 transition-all outline-none placeholder:text-outline/20"
              />
            </div>

            <button 
              type="submit"
              disabled={isLoading || otp.length < 6}
              className="w-full bg-primary text-on-surface py-6 rounded-[2rem] font-headline font-extrabold text-xl flex items-center justify-center gap-3 shadow-2xl shadow-primary/30 hover:brightness-110 active:scale-95 transition-all disabled:opacity-50"
            >
              {isLoading ? 'Verifying...' : 'Verify & Sign In'}
              <CheckCircle2 className="w-6 h-6" />
            </button>
          </form>

          <footer className="text-center space-y-4">
             <p className="text-sm text-outline font-medium">Didn't receive the code?</p>
             <button className="text-primary font-extrabold uppercase text-xs tracking-[0.2em] hover:underline">Resend OTP</button>
          </footer>
        </section>
      </motion.div>
      
      {/* Background Noise Texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.03] z-[100] bg-[url('https://www.transparenttextures.com/patterns/cubes.png')]" />
    </div>
  );
};
