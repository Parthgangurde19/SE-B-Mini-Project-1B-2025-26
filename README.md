# SE-B-Mini-Project-1B-2025-26
# AutoHub v3.0 — Market-Ready Vehicle Marketplace

## 🚀 Quick Start

### Step 1 — Install dependencies
```bash
flutter pub get
```

### Step 2 — Configure Firebase (required)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Auto-configure (fills firebase_options.dart automatically)
flutterfire configure
```
Or manually fill `lib/firebase_options.dart` from Firebase Console → Project Settings.

### Step 3 — Enable Firebase services
In Firebase Console, enable:
- ✅ Authentication → Phone, Email/Password, Google
- ✅ Firestore Database
- ✅ Storage

### Step 4 — Google Sign-In setup
Add SHA-1 fingerprint to Firebase Console:
```bash
cd android
./gradlew signingReport
# Copy the SHA1 and add it to Firebase Console → Project Settings → Android App
```

### Step 5 — Set your UPI ID
Open `lib/services/upi_service.dart`:
```dart
const String kBusinessUpiId = 'yourname@okaxis'; // ← your real UPI ID
```

### Step 6 — Run
```bash
flutter run
```

---

## 📱 Demo Credentials
- **Admin:** admin@autohub.com / admin123
- **Customer:** any email + any password (auto-creates account)

---

## ✨ Features

### Customer
| Feature | Details |
|---|---|
| Onboarding | 3-slide animated intro |
| Auth | Google Sign-In ✅,  Email/Password |
| Browse | FOR SALE + FOR RENT tabs, search, filter, sort |
| Vehicle Detail | Image gallery, specs, features, EMI calc, reviews |
| Rental Booking | 3-step wizard, **real-time conflict detection**, UPI payment |
| Buy / Test Drive | Purchase enquiry + dealer test drive booking |
| Services | 5 services with slot availability, booking, UPI payment |
| Spare Parts | Catalog, cart, checkout (UPI/Card/COD), order tracking |
| Reviews | Star ratings, tags, helpful votes — atomic Firestore updates |
| Wishlist | Save vehicles with heart button |
| My Bookings | Active, completed, cancelled with cancel option |
| Profile | Stats, saved vehicles, booking history |

### Admin
| Feature | Details |
|---|---|
| Dashboard | KPI cards, pending requests, inventory summary |
| Requests | Pending/Approved/Rejected tabs, approve/reject with notes |
| Add Vehicle | Full form with image upload to Firebase Storage |
| Add Part | Full form with specs, compatibility, images |
| Add Service | Dynamic lists for includes/excludes/requirements/slots |
| Edit/Delete | All inventory items editable and deletable |

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # Entry point + provider setup
├── firebase_options.dart        # Firebase config (fill this!)
├── theme/app_theme.dart         # Design system
├── models/                      # Data models (6 files)
├── providers/                   # State management (7 providers)
├── screens/
│   ├── onboarding/              # 3-slide intro
│   ├── auth/                    # Login (Google + Phone + Email)
│   ├── home/                    # Browse + Vehicle Detail
│   ├── rental/                  # Rental booking with conflict detection
│   ├── services/                # Service listing + booking
│   ├── parts/                   # Parts shop + cart + checkout
│   ├── bookings/                # My bookings history
│   ├── reviews/                 # Write review screen
│   ├── profile/                 # User profile
│   └── admin/                   # Admin dashboard + all CRUD forms
├── services/
│   ├── upi_service.dart         # UPI deep-link payment
│   └── image_upload_service.dart # Firebase Storage upload
├── widgets/                     # Shared UI components
└── utils/                       # Constants, helpers, validators
```

---

## 🔒 Firestore Security Rules (add in Firebase Console)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    match /vehicles/{id} {
      allow read: if true;
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }
    match /vehicles/{id}/bookedSlots/{slotId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }
    match /requests/{id} {
      allow read: if request.auth != null &&
        (resource.data.userId == request.auth.uid ||
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin');
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }
    match /reviews/{id} {
      allow read: if true;
      allow create: if request.auth != null;
    }
    match /{collection}/{id} {
      allow read: if true;
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }
  }
}
```

---

## 🏪 Market Positioning
Competitive with: **OLX Autos**, **CarDekho**, **BikeWale**, **Spinny**

Differentiators:
- Real-time rental slot conflict prevention
- Atomic rating updates (no race conditions)
- Full admin CMS with image upload
- UPI auto-launch across all payment flows
- Detailed product descriptions (150+ words each)
- EMI calculator on vehicle detail
