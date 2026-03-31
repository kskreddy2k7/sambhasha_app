# Sambhasha — Secure, Production-Ready Full-Stack Chat & Calling App

Sambhasha is a multi-platform, production-ready messaging and calling platform built with:
- **Flutter** (Android mobile app)
- **React + Vite** (Web frontend → Vercel)
- **Node.js + Socket.IO** (WebRTC Signaling Server → Render)
- **Firebase** (Auth, Firestore, Storage, FCM)

---

## 🚀 Features

| Feature | Flutter App | Web App |
|---------|------------|---------|
| Google Sign-In | ✅ | ✅ |
| Phone OTP Auth | ✅ | — |
| Real-time Firestore Chat | ✅ | ✅ |
| Typing Indicators | ✅ | ✅ |
| Message Status (sent/delivered/seen) | ✅ | ✅ |
| WebRTC Video & Audio Calling | ✅ | ✅ |
| AI Assistant (Gemini Pro) | ✅ | — |
| End-to-End Encryption | ✅ | — |
| Push Notifications (FCM) | ✅ | — |
| Stories/Status | ✅ | — |
| Dark Mode | ✅ | ✅ |

---

## 🔐 Security

- **No hardcoded API keys anywhere in the codebase.**
- Flutter uses `String.fromEnvironment()` / `--dart-define` for all Firebase config.
- Web app uses `VITE_FIREBASE_*` environment variables.
- Signaling server uses `process.env.*` variables.
- `google-services.json` and all `.env` files are excluded from git.

---

## 📁 Repository Structure

```
sambhasha_app/
├── lib/                      # Flutter app source
│   ├── firebase_options.dart # Firebase config via String.fromEnvironment
│   ├── services/             # Auth, DB, Call, AI services
│   ├── screens/              # All UI screens
│   └── ...
├── server/                   # Node.js WebRTC Signaling Server (→ Render)
│   ├── server.js
│   ├── package.json
│   ├── render.yaml
│   └── .env.example
├── web-app/                  # React + Vite Web Frontend (→ Vercel)
│   ├── src/
│   │   ├── firebase.js       # Firebase init from env vars
│   │   ├── components/       # LoginScreen, ChatList, ChatScreen, VideoCall
│   │   ├── hooks/useWebRTC.js
│   │   └── styles/globals.css
│   ├── vercel.json
│   └── .env.example
├── android/                  # Android build files
├── .env.example.json         # Flutter env vars template
└── firestore.rules
```

---

## ⚙️ Setup

### 1. Firebase Project

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Authentication** → Google Sign-In (and Phone for Flutter).
3. Enable **Firestore Database** in production mode.
4. Enable **Firebase Storage**.
5. Add Android app (package: `com.sai.sambhasa_app`) and download `google-services.json` → place in `android/app/`.
6. Add Web app and note your Firebase config values.
7. Deploy Firestore rules: copy `firestore.rules` → Firestore > Rules.

---

### 2. Flutter Mobile App (Android APK)

Copy `.env.example.json` to `.env.json` and fill in your Firebase values:

```json
{
  "FIREBASE_WEB_API_KEY": "AIzaSy...",
  "FIREBASE_WEB_APP_ID": "1:...:web:...",
  "FIREBASE_ANDROID_API_KEY": "AIzaSy...",
  "FIREBASE_ANDROID_APP_ID": "1:...:android:...",
  "FIREBASE_MESSAGING_SENDER_ID": "...",
  "FIREBASE_PROJECT_ID": "your-project-id",
  "FIREBASE_AUTH_DOMAIN": "your-project.firebaseapp.com",
  "FIREBASE_STORAGE_BUCKET": "your-project.firebasestorage.app",
  "FIREBASE_MEASUREMENT_ID": "G-...",
  "GEMINI_API_KEY": "AIzaSy..."
}
```

**Run / Build:**

```bash
# Install dependencies
flutter pub get

# Run on Android device/emulator
flutter run --dart-define-from-file=.env.json

# Build release APK
flutter build apk --dart-define-from-file=.env.json --release

# Run on Chrome (web)
flutter run -d chrome --dart-define-from-file=.env.json
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

### 3. Signaling Server (Render)

```bash
cd server
cp .env.example .env
# Edit .env: set ALLOWED_ORIGINS to your Vercel frontend URL
```

**Deploy to Render:**

The `server/render.yaml` is pre-configured. Connect your GitHub repo to [render.com](https://render.com), select the `server/` root directory, and deploy. Environment variables to set in Render dashboard:

| Variable | Value |
|----------|-------|
| `PORT` | Auto-assigned by Render |
| `ALLOWED_ORIGINS` | `https://your-app.vercel.app` |

**Local development:**

```bash
cd server
npm install
npm run dev      # uses nodemon
# or
npm start        # production
```

Health check: `GET /health` → `{ status: "ok", rooms: N, uptime: ... }`

---

### 4. React Web App (Vercel)

```bash
cd web-app
cp .env.example .env
# Fill in your Firebase values and signaling server URL
```

`.env` contents:

```env
VITE_FIREBASE_API_KEY=AIzaSy...
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
VITE_FIREBASE_STORAGE_BUCKET=your-project.firebasestorage.app
VITE_FIREBASE_MESSAGING_SENDER_ID=...
VITE_FIREBASE_APP_ID=1:...:web:...
VITE_FIREBASE_MEASUREMENT_ID=G-...
VITE_SIGNALING_SERVER_URL=https://your-signaling-server.onrender.com
```

**Local development:**

```bash
cd web-app
npm install
npm run dev
```

**Deploy to Vercel:**

1. Push this repo to GitHub.
2. Import project in [vercel.com](https://vercel.com) — set **Root Directory** to `web-app`.
3. Add all `VITE_*` environment variables in Vercel project settings.
4. Deploy. The `vercel.json` handles SPA routing fallback automatically.

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter 3 + Dart |
| Web Frontend | React 18 + Vite 5 |
| State (Flutter) | Provider |
| Auth | Firebase Authentication (Google, Phone) |
| Database | Cloud Firestore (real-time) |
| Storage | Firebase Storage |
| Push Notifications | Firebase Cloud Messaging |
| Video/Audio Calls | WebRTC (flutter_webrtc / browser RTCPeerConnection) |
| Call Signaling | Socket.IO (Node.js server) / Firestore (Flutter) |
| AI Features | Google Gemini Pro |
| Encryption | RSA-2048 + AES-256 (Flutter) |
| Backend Server | Node.js + Express + Socket.IO |
| Deployment (web) | Vercel |
| Deployment (server) | Render |

---

## 🔒 Security Notes

- All API keys and secrets must be supplied via environment variables — never commit `.env` files.
- Flutter reads credentials at build time via `--dart-define-from-file=.env.json`.
- The `google-services.json` file is gitignored; obtain it from your Firebase console.
- Firestore security rules (`firestore.rules`) enforce that users can only read/write their own data.
- CORS on the signaling server is restricted to your frontend origin via `ALLOWED_ORIGINS`.

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| Firebase not initializing | Check all `FIREBASE_*` env vars are set and not placeholder values |
| Google Sign-In fails on web | Ensure your domain is in Firebase → Auth → Authorized Domains |
| WebRTC call not connecting | Ensure signaling server is running and `VITE_SIGNALING_SERVER_URL` is correct |
| APK crashes on start | Verify `google-services.json` is in `android/app/` and matches your Firebase project |
| Vercel 404 on refresh | `vercel.json` SPA fallback is included — ensure it is deployed with root in `web-app/` |

