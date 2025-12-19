# Campus Companion

A comprehensive university companion mobile application built with Flutter and Firebase, designed to help students, professors, and administrators manage campus announcements, tasks, and user accounts efficiently.

## 🎯 Overview

Campus Companion is a full-featured campus management system that provides role-based access control for different user types (students, professors, admins) with a clean Material Design 3 interface.

## 🚀 Tech Stack

- **Flutter** 3.5.0+ (Dart 3.10+)
- **Firebase Suite**:
  - Firebase Authentication (Email/Password)
  - Cloud Firestore (Real-time database)
  - Firebase Security Rules (Role-based access control)
- **State Management**: Provider (ChangeNotifier pattern)
- **HTTP Client**: http package
- **UI**: Material Design 3, Lottie animations
- **Navigation**: Named routes with deep linking support

## ✨ Key Features

### 🔐 Authentication & User Management
- Email/password registration and login
- Role-based authentication (Student, Professor, Admin)
- User profile management with editable display names
- Account suspension system for security
- Admin dashboard for user management

### 📢 Announcements System
- Create, edit, and delete announcements (Professors & Admins)
- Category-based organization with multi-select filters
- Date range filtering for announcements
- Full-text search with "starts with" and "contains" options
- Detailed announcement view with hero animations
- Announcement categories management (Admin only)

### ✅ Task Management
- Personal task lists with due date tracking
- Overdue task highlighting (red text, bold)
- Task status tracking (done/not done)
- Due date filtering (on time/overdue)
- Search functionality with flexible filters
- Task completion with visual feedback

### 👥 Admin Features
- User management dashboard with statistics
- Edit user roles (Student, Professor, Admin)
- Suspend/unsuspend user accounts
- Category management with search
- Real-time user count and announcement statistics

### 🎨 UI/UX Features
- Bottom navigation bar for main sections
- Navigation drawer with role-based menu items
- Hero animations for smooth transitions
- Animated loading states with opacity transitions
- Search bars with filter toggles on all list pages
- Responsive scrolling on all screens
- Material Design 3 color schemes

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase configuration
├── models/                      # Data models
│   ├── app_user.dart           # User model with roles
│   ├── task.dart               # Task model with due dates
│   ├── announcement.dart       # Announcement model
│   └── category.dart           # Category model
├── providers/                   # State management
│   ├── auth_provider.dart      # Authentication state
│   ├── task_provider.dart      # Task state
│   ├── announcement_provider.dart
│   ├── category_provider.dart
│   └── users_provider.dart     # Admin user management
├── screens/                     # UI screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart        # Main dashboard
│   ├── profile_screen.dart
│   ├── tasks_list_screen.dart
│   ├── task_edit_screen.dart
│   ├── announcements_list_screen.dart
│   ├── announcement_detail_screen.dart
│   ├── announcement_edit_screen.dart
│   └── admin_dashboard_screen.dart
├── services/                    # Backend services
│   ├── firestore_service.dart  # Firestore operations
│   └── api_service.dart        # HTTP API calls
└── routes/
    └── app_routes.dart         # Centralized routing

android/                         # Android configuration
ios/                            # iOS configuration
```

## 🔧 Firebase Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "Campus Companion"
3. Enable Google Analytics (optional)

### 2. Enable Authentication
1. Navigate to **Authentication** → **Sign-in method**
2. Enable **Email/Password** authentication
3. Save changes

### 3. Create Firestore Database
1. Navigate to **Firestore Database**
2. Click **Create database**
3. Choose production mode or test mode
4. Select your region

### 4. Set Firestore Security Rules
Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAdmin() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    function isProfessor() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'professor';
    }

    function isSuspended() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.get('isSuspended', false) == true;
    }

    match /users/{userId} {
      allow read: if request.auth.uid == userId || isAdmin();
      allow write: if (request.auth.uid == userId && !isSuspended()) || isAdmin();

      match /tasks/{taskId} {
        allow read, write: if request.auth.uid == userId;
      }
    }

    match /announcements/{announcementId} {
      allow read: if request.auth != null && !isSuspended();
      allow write: if (isProfessor() || isAdmin()) && !isSuspended();
    }

    match /categories/{categoryId} {
      allow read: if request.auth != null && !isSuspended();
      allow write: if isAdmin() && !isSuspended();
    }
  }
}
```

### 5. Add Firebase to Your Apps

#### Android Setup
1. In Firebase Console, add an **Android app**
2. Package name: `com.example.campus_companion`
3. Download `google-services.json`
4. Place it in `android/app/`

#### iOS Setup
1. In Firebase Console, add an **iOS app**
2. Bundle ID: `com.example.campusCompanion`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/`

## 📦 Installation

### Prerequisites
- Flutter SDK 3.5.0 or higher
- Dart 3.10 or higher
- Android Studio / Xcode (for mobile development)
- Firebase account

### Steps

1. **Clone the repository**
```bash
git clone <your-repo-url>
cd flutter
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase**
- Follow the Firebase Setup section above
- Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in place

4. **Run the app**
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or just run on default device
flutter run
```

## 🧪 Testing

### Create Test Users
After running the app, register users with different roles:

1. **Admin User**
   - Register normally, then manually update Firestore:
   - Go to Firestore Console → `users` → your user document
   - Edit `role` field to `"admin"`

2. **Professor User**
   - Register with email/password
   - Have admin change role to "professor"

3. **Student User**
   - Register normally (default role)

### Test Scenarios
- ✅ Student can view announcements and manage personal tasks
- ✅ Professor can create/edit announcements
- ✅ Admin can manage users, categories, and all content
- ✅ Suspended users cannot access the app
- ✅ Search and filter work on all list screens
- ✅ Overdue tasks display in red
- ✅ Role-based menu items show correctly

## 🎨 UI Screenshots

Key screens include:
- Login & Registration with animated loading states
- Home Dashboard with announcements and task previews
- Announcements List with search and category filters
- Tasks List with due date tracking and overdue highlighting
- Admin Dashboard with user management and statistics
- Profile screen with editable display name

## 🔒 Security Features

- **Role-based access control** enforced at Firestore rules level
- **Account suspension** prevents access for flagged users
- **Field-level write restrictions** prevent privilege escalation
- **Authentication required** for all data access
- **Input validation** on all forms
- **Error handling** with user-friendly messages

## 🚀 Deployment

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS IPA (requires Apple Developer account)
```bash
flutter build ios --release
```

## 📝 Known Issues & Limitations

- Google Play Services warnings on emulators without Play Store (harmless)
- iOS requires proper provisioning profile for release builds
- Large user lists in admin dashboard may need pagination
- No offline support (requires internet connection)

## 🛠️ Future Enhancements

- Push notifications for new announcements
- Offline caching with local database
- File attachments for announcements
- Recurring tasks
- Calendar integration
- Dark mode support
- Multi-language support (i18n)

## 📄 License

This project is for educational purposes.

## 👥 Contributing

Contributions, issues, and feature requests are welcome!

## 📞 Support

For issues or questions, please open an issue on the repository.
