import { 
  RecaptchaVerifier, 
  signInWithPhoneNumber, 
  ConfirmationResult,
  onAuthStateChanged,
  User
} from 'firebase/auth';
import { auth } from '../lib/firebase';

export const authService = {
  // 1. Initialize Recaptcha
  setupRecaptcha: (containerId: string) => {
    if ((window as any).recaptchaVerifier) return;
    (window as any).recaptchaVerifier = new RecaptchaVerifier(auth, containerId, {
      size: 'invisible',
      callback: () => {
        // reCAPTCHA solved, allow signInWithPhoneNumber.
      }
    });
  },

  // 2. Send OTP
  sendOTP: async (phoneNumber: string): Promise<ConfirmationResult> => {
    const appVerifier = (window as any).recaptchaVerifier;
    return await signInWithPhoneNumber(auth, phoneNumber, appVerifier);
  },

  // 3. Verify OTP
  verifyOTP: async (confirmationResult: ConfirmationResult, code: string) => {
    return await confirmationResult.confirm(code);
  },

  // 4. Logout
  logout: () => auth.signOut(),

  // 5. Subscribe to auth state
  onAuthChange: (callback: (user: User | null) => void) => {
    return onAuthStateChanged(auth, callback);
  }
};
