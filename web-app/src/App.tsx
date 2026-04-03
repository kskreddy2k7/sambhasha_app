import { useState, useEffect } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { LoginScreen } from './screens/LoginScreen';
import { OTPScreen } from './screens/OTPScreen';
import { ChatListScreen } from './screens/ChatListScreen';
import { StoriesScreen } from './screens/StoriesScreen';
import { ActiveCallScreen } from './screens/ActiveCallScreen';
import { SettingsScreen } from './screens/SettingsScreen';
import { CallsScreen } from './screens/CallsScreen';

import { authService } from './services/authService';

function App() {
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = authService.onAuthChange((u) => {
      setUser(u);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  if (loading) return (
    <div className="h-screen flex items-center justify-center bg-surface">
      <div className="w-12 h-12 border-4 border-primary border-t-transparent rounded-full animate-spin" />
    </div>
  );

  return (
    <div className="bg-surface text-on-surface font-sans antialiased min-h-screen">
      <Routes>
        <Route path="/" element={user ? <Navigate to="/chats" replace /> : <LoginScreen />} />
        <Route path="/otp" element={user ? <Navigate to="/chats" replace /> : <OTPScreen />} />
        
        {/* Protected Routes */}
        <Route path="/chats" element={user ? <ChatListScreen /> : <Navigate to="/" replace />} />
        <Route path="/calls" element={user ? <CallsScreen /> : <Navigate to="/" replace />} />
        <Route path="/stories" element={user ? <StoriesScreen /> : <Navigate to="/" replace />} />
        <Route path="/call" element={user ? <ActiveCallScreen /> : <Navigate to="/" replace />} />
        <Route path="/settings" element={user ? <SettingsScreen /> : <Navigate to="/" replace />} />
        
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </div>
  );
}

export default App;
