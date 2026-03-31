import { initializeApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const requiredVars = [
  'VITE_FIREBASE_API_KEY',
  'VITE_FIREBASE_AUTH_DOMAIN',
  'VITE_FIREBASE_PROJECT_ID',
  'VITE_FIREBASE_APP_ID',
];

const PLACEHOLDER_PATTERN = /^(your-|YOUR_|<|$)/;

const missingVars = requiredVars.filter(
  (key) => !import.meta.env[key] || PLACEHOLDER_PATTERN.test(import.meta.env[key])
);

if (missingVars.length > 0) {
  console.warn(
    `[Sambhasha] Missing or placeholder Firebase env vars: ${missingVars.join(', ')}. ` +
    'Copy .env.example to .env and fill in your Firebase project values.'
  );
}

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID,
};

export const isFirebaseConfigured = missingVars.length === 0;

let app = null;
let auth = null;
let db = null;
let googleProvider = null;

try {
  app = initializeApp(firebaseConfig);
  auth = getAuth(app);
  db = getFirestore(app);
  googleProvider = new GoogleAuthProvider();
  googleProvider.addScope('profile');
  googleProvider.addScope('email');
} catch (error) {
  console.error('[Sambhasha] Firebase initialization failed:', error.message);
}

export { auth, db, googleProvider };
export default app;
