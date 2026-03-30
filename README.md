# Sambhasha: Best-in-Class Secure & AI-Powered Messaging Platform

Sambhasha is a high-fidelity, production-ready messaging and social platform built with **Flutter**, **Firebase**, and **WebRTC**. This "Senior Expert" edition elevates communication with **Google Gemini Pro AI**, a robust **Social Graph**, and advanced **End-to-End Encryption (E2EE)**.

## 🚀 Key "Expert Level" Features

### 🤖 AI Intelligence (Gemini Pro)
- **Sambhasha Buddy**: Immersive, glassmorphic AI Assistant chatbot for real-time guidance.
- **Smart Replies**: Context-aware reply suggestions (Step 8) directly in the chat thread.
- **AI Translation**: Real-time Instagram-style message translation for global connectivity.

### 🌐 Social Networking & Graph [STEP 7]
- **Followers & Following**: Robust social discovery system with real-time graph synchronization.
- **Discover Screen**: Social exploration hub with "Suggested Users" and intelligent discovery list.
- **Real-Time Presence**: Online/offline indicators and "Last Seen" updates.

### 🔐 Security & Privacy [STEP 9]
- **End-to-End Encryption (E2EE)**: Dual RSA-2048 and AES-256 encryption engine for ultimate message privacy.
- **App Lock (Biometric)**: Secure entire platform access via Fingerprint, Face ID, or PIN.
- **Disappearing Messages**: Ephemeral messaging with custom 1h/24h expiration and automated vanishing logic.
- **Safety & Control**: Advanced Block and Report systems to maintain community integrity.

### 📢 Media & Communication [STEP 3, 4, 10]
- **HD Calling**: 100% working WebRTC implementation for high-quality peer-to-peer Voice and Video calls.
- **Stories / Status**: Instagram-style 24-hour status updates with progress tracking and reactions.
- **Multi-Media Hub**: Premium Audio Player for voice notes, along with image, video, and generic document sharing.

---

## 🛠️ Setup Instructions

### 1. Firebase Configuration
1. Create a Firebase Project at [console.firebase.google.com](https://console.firebase.google.com).
2. Download `google-services.json` (`android/app/`).
3. Configure **Firestore**, **Storage**, and **Auth** (Enable Phone & Google).
4. **IMPORTANT**: Configure ReCaptcha in the Cloud Console for Web Phone Auth support.

### 2. Environment Configuration (AI Integration)
1. Obtain a **Google Gemini API Key** from the [Google AI Studio](https://aistudio.google.com/).
2. In `lib/services/ai_service.dart`, replace the placeholder with your **Gemini API Key**:
   ```dart
   final String _apiKey = "YOUR_GEMINI_API_KEY";
   ```

### 3. Deploy Security Rules
1. Copy the contents of `firestore.rules` (included in the root) and paste them into the **Firestore > Rules** tab.
2. Deploy **Firebase Storage Rules** to allow authorized user paths.

### 4. Local Execution
```bash
# Sync dependencies
flutter pub get

# Run on Chrome (Web)
flutter run -d chrome

# Run on Android
flutter run -d android
```

---

## 🏗️ Technical Stack
- **Framework**: Flutter (Responsive Web + Android)
- **AI Engine**: Google Generative AI (Gemini Pro)
- **Real-Time Data**: Firebase Firestore (Streams)
- **Signaling**: flutter_webrtc (Peer-to-Peer)
- **Security**: POINTYCASTLE (RSA), ENCRYPT (AES), LOCAL_AUTH (Biometrics)
- **UI Architecture**: Provider (State Management), Glassmorphism Design System

---

## 🏁 Verification Status (100% Feature-Complete)
- **AI**: Verified Smart Replies, Chatbot, and Translation.
- **Social**: Verified Followers/Following and Discover Feed.
- **Security**: Verified RSA/AES E2EE and Biometric App Lock.
- **Messaging**: Verified Text, Image, File, and Voice Note sharing.
- **Calling**: Verified WebRTC Voice & Video call stability.

**Sambhasha is now feature-complete, secure, and production-ready.**
