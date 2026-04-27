# 🎓 CodeClub

A Flutter-based mobile application designed exclusively for **APSIT students** to find their perfect hackathon team members, create and manage teams, and register for hackathons. Built with Firebase backend and modern Flutter architecture.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange?logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📋 Table of Contents

- [Features](#-features)
- [Project Architecture](#-project-architecture)
- [Tech Stack](#-tech-stack)
- [Installation & Setup](#-installation--setup)
- [Firebase Configuration](#-firebase-configuration)
- [Directory Structure](#-directory-structure)
- [Key Services](#-key-services)
- [Database Schema](#-database-schema)
- [Development Guide](#-development-guide)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Features

### Core Features
- **👤 User Profiles**: Complete profile setup with skills, branch, year, and bio
- **🔍 Smart Team Matching**: Discover team members based on skills, roles, and academic background
- **👥 Team Management**: Create teams, send invitations, and manage team members
- **💬 Real-time Chat**: Communicate with team members and community
- **🏆 Hackathon Hub**: Browse, register, and manage hackathon participation
- **🤖 AI Mentor**: Intelligent chatbot for guidance and support
- **💬 Community Chat**: Connect with the broader APSIT community
- **🔔 Notifications**: Real-time push notifications for team activities and events
- **🌐 Offline Support**: Basic functionality available without internet

### Admin Features
- **📊 Hackathon Management**: Create and manage hackathons
- **👨‍💼 User Management**: Manage user accounts and roles
- **⚙️ System Configuration**: Control app-wide settings
- **📈 Analytics & Insights**: View statistics and user engagement

---

## 🏗️ Project Architecture

CodeClub follows a **layered architecture** pattern for clean code separation:

```
lib/
├── ui/                    # Presentation Layer (Screens & Widgets)
│   ├── screens/          # Feature-based screens
│   ├── widgets/          # Reusable UI components
│   ├── admin/            # Admin dashboard
│   └── navigation/       # App routing (GoRouter)
├── data/                 # Data Layer
│   ├── services/         # Firebase & API services
│   └── models/           # Data models
├── features/             # Feature-specific logic
│   ├── ai_mentor/        # AI mentor feature
│   └── ...
├── providers/            # State Management (Provider)
├── core/                 # Core Utilities & Constants
│   ├── constants/        # App constants
│   ├── theme/            # Theme configuration
│   └── utils/            # Helper utilities
└── main.dart             # App entry point
```

---

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.x+** - Cross-platform mobile framework
- **Provider** - State management solution
- **GoRouter** - Navigation and routing
- **Material Design 3** - Modern UI design system

### Backend & Services
- **Firebase Authentication** - Secure user authentication
- **Cloud Firestore** - Real-time NoSQL database
- **Firebase Storage** - Cloud file storage for images
- **Firebase App Check** - Security and abuse prevention

### Additional Libraries
- **cached_network_image** - Image caching and optimization
- **flutter_local_notifications** - Push notifications
- **connectivity_plus** - Internet connectivity detection
- **image_picker** - Media selection from device
- **url_launcher** - Open links and make calls
- **lottie** - Beautiful animations
- **flutter_markdown** - Markdown rendering

---

## 📦 Installation & Setup

### Prerequisites
- Flutter SDK ≥ 3.10.8
- Dart SDK ≥ 3.10.8
- Android SDK (for Android builds)
- Xcode (for iOS builds)
- Firebase account and project

### Step 1: Clone Repository
```bash
git clone https://github.com/Pushkar3232/CodeClub.git
cd CodeClub
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Firebase Setup
The app uses Firebase with the following services enabled:
- Firestore Database
- Firebase Authentication
- Firebase Storage
- Firebase App Check

**Configuration files are auto-generated** - ensure the following are properly set:
- `android/app/google-services.json` (Android)
- `GoogleService-Info.plist` (iOS)
- `lib/firebase_options.dart` (Auto-generated)

To regenerate Firebase configuration:
```bash
flutterfire configure
```

### Step 4: Run the App
```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Web platform
flutter run -d chrome

# Specific device
flutter run -d <device_id>
```

---

## 🔐 Firebase Configuration

### Firestore Rules
The app uses role-based access control with the following rules:

```firestore
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Users - read own & others for matching, only admins control
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null;  // For team matching
      allow read, write: if request.auth != null && request.auth.token.admin == true;
    }
    
    // Teams - authenticated users can read, leaders/members can write
    match /teams/{teamId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                      request.auth.uid == request.resource.data.leaderId;
      allow update, delete: if request.auth != null && 
                             (request.auth.uid == resource.data.leaderId ||
                              request.auth.uid in resource.data.memberIds ||
                              request.auth.token.admin == true);
    }
    
    // Team Requests - users can manage their requests
    match /team_requests/{requestId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                      request.resource.data.fromUserId == request.auth.uid;
      allow update: if request.auth != null && 
                      (resource.data.fromUserId == request.auth.uid ||
                       resource.data.toUserId == request.auth.uid);
      allow delete: if request.auth != null && 
                      resource.data.fromUserId == request.auth.uid;
    }
    
    // Hackathons - read-only for users, write for admins
    match /hackathons/{hackathonId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### Required Collections
- **users** - User profiles and account data
- **teams** - Team information and members
- **team_requests** - Team invitation requests
- **hackathons** - Hackathon events and registration
- **admins** - Admin role management
- **chats** - Chat messages and conversations (if enabled)

---

## 📂 Directory Structure

```
lib/
├── ui/
│   ├── screens/
│   │   ├── auth/           # Authentication screens
│   │   ├── profile/        # User profile management
│   │   ├── home/           # Home/dashboard screens
│   │   ├── members/        # Team member browsing
│   │   ├── hackathon/      # Hackathon screens
│   │   ├── chat/           # Chat screens
│   │   └── admin/          # Admin dashboard
│   ├── widgets/            # Reusable UI components
│   └── navigation/         # App routing
├── data/
│   ├── services/
│   │   ├── auth_service.dart        # Firebase Auth
│   │   ├── user_service.dart        # User data operations
│   │   ├── chat_service.dart        # Chat functionality
│   │   ├── team_service.dart        # Team management
│   │   ├── hackathon_service.dart   # Hackathon operations
│   │   ├── admin_service.dart       # Admin functions
│   │   └── notification_service.dart # Push notifications
│   └── models/             # Data models
├── features/
│   └── ai_mentor/          # AI mentor chatbot
├── providers/              # State management
│   ├── auth_provider.dart
│   ├── chat_provider.dart
│   ├── admin_provider.dart
│   ├── hackathon_provider.dart
│   ├── connectivity_provider.dart
│   └── theme_provider.dart
├── core/
│   ├── constants/          # App-wide constants
│   ├── theme/              # Theme & styling
│   └── utils/              # Helper functions
└── main.dart               # Entry point
```

---

## 🔧 Key Services

### AuthService
Handles Firebase Authentication with email/password sign-up and login.

### UserService
Manages user profile creation, updates, and retrieval from Firestore.

### ChatService
Provides real-time messaging between team members using Firestore.

### HackathonService
Manages hackathon data, registration, and status updates.

### AdminService
Admin-only operations including user management and hackathon creation.

### NotificationService
Sends push notifications for team invites, messages, and hackathon updates.

### ConnectivityService
Monitors internet connection status and handles offline scenarios.

---

## 💾 Database Schema

### Users Collection
```dart
{
  userId: String,           // Firebase UID
  name: String,
  email: String,
  branch: String,          // Engineering branch
  year: int,               // Academic year
  skills: List<String>,    // Technical skills
  bio: String,
  profileImage: String,    // Storage URL
  role: String,            // 'user' or 'admin'
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Teams Collection
```dart
{
  teamId: String,
  name: String,
  description: String,
  leaderId: String,        // Team lead user ID
  memberIds: List<String>, // Member user IDs
  hackathonId: String,
  imageUrl: String,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Hackathons Collection
```dart
{
  hackathonId: String,
  name: String,
  description: String,
  startDate: Timestamp,
  endDate: Timestamp,
  location: String,
  maxTeamSize: int,
  imageUrl: String,
  status: String,          // 'upcoming', 'ongoing', 'completed'
  createdAt: Timestamp
}
```

---

## 🚀 Development Guide

### Running Tests
```bash
# Widget tests
flutter test

# Specific test file
flutter test test/widget_test.dart
```

### Code Formatting
```bash
# Format all files
dart format lib/

# Check formatting
dart format --line-length=100 lib/
```

### Linting
```bash
# Analyze code
flutter analyze
```

### Building Releases

**Android:**
```bash
flutter build apk --release
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Commit** your changes:
   ```bash
   git commit -m "Add: Description of your feature"
   ```
4. **Push** to your branch:
   ```bash
   git push origin feature/your-feature-name
   ```
5. **Create** a Pull Request with a detailed description

### Code Style
- Follow Dart style guidelines
- Use meaningful variable and function names
- Add documentation for public APIs
- Keep commits atomic and descriptive

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Pushkar** - [@Pushkar3232](https://github.com/Pushkar3232)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- APSIT community for continuous support
- All contributors who help improve this project

---

## 📞 Support

For questions, issues, or feature requests:
- Open an [GitHub Issue](https://github.com/Pushkar3232/CodeClub/issues)
- Check existing [documentation](./doc/)
- Review [GitHub discussions](https://github.com/Pushkar3232/CodeClub/discussions)

---

**Last Updated**: April 2026 | **Version**: 1.0.0

Thank you for using CodeClub! Happy hacking!
