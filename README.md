# 🚀 Sambhasha — Modern Messaging App

Sambhasha is a real-time messaging application inspired by Instagram and WhatsApp, built using **Flutter + Firebase**.

It allows users to connect using usernames, chat instantly, and share media in a clean and modern UI.

---

## ✨ Features

### 🔐 Authentication

* Email & Password login
* Google Sign-In (optional)
* Secure Firebase Authentication

### 👤 User Profiles

* Unique username system
* Profile photo, bio, and name
* Edit profile functionality

### 🔍 Search

* Real-time user search
* Find users by username
* Start conversations instantly

### 💬 Chat System

* 1-to-1 real-time messaging
* Message bubbles (Instagram style)
* Seen / delivered status
* Timestamp formatting

### 📎 Media Sharing

* Send images
* Send files (PDF, Docs)
* Firebase Storage integration

### 🟢 User Status

* Online / Offline indicator
* Last seen

### 🔔 Notifications

* Firebase Cloud Messaging (planned / in progress)

---

## 🎨 UI / UX

* Premium dark theme 🌙
* Clean and minimal design
* Smooth animations
* Responsive layout

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase

  * Authentication
  * Cloud Firestore
  * Firebase Storage
  * Cloud Messaging (FCM)

---

## 📁 Project Structure

```
lib/
 ├── core/
 ├── models/
 ├── screens/
 │    ├── auth/
 │    ├── chat/
 │    ├── profile/
 │    ├── search/
 │    ├── splash/
 ├── services/
 ├── widgets/
 ├── main.dart
```

---

## ⚙️ Setup Instructions

### 1️⃣ Clone the repository

```bash
git clone https://github.com/kskreddy2k7/sambhasha_app.git
cd sambhasha_app
```

---

### 2️⃣ Install dependencies

```bash
flutter pub get
```

---

### 3️⃣ Firebase Setup (IMPORTANT 🔐)

This project does NOT include Firebase config for security.

👉 You must add your own:

1. Go to Firebase Console
2. Create a project
3. Add Android app
4. Download:

```
google-services.json
```

5. Place it in:

```
android/app/google-services.json
```

---

### 4️⃣ Run the app

```bash
flutter run
```

---

## 🔒 Security

* Firebase config files are excluded from GitHub
* Firestore rules should be configured properly
* No sensitive keys are exposed

---

## 🚀 Build APK

```bash
flutter build apk --release
```

APK location:

```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📌 Future Improvements

* 📞 Voice & Video Calls
* 🔔 Push Notifications
* 📸 Stories Feature
* 🌐 Web version optimization
* ⚡ Performance improvements

---

## 🤝 Contributing

Contributions are welcome!
Feel free to fork the repo and submit pull requests.

---

## 📄 License

This project is open-source and available under the MIT License.

---

## 👨‍💻 Developer

**Kata Sai Kranthu Reddy**

* GitHub: https://github.com/kskreddy2k7

---

## ⭐ Support

If you like this project, please ⭐ the repository!

---
