## Campus Companion (Flutter Mini-Project)

Campus Companion is a simple, university-oriented Flutter application that helps students manage announcements, tasks, and basic profile/settings.  
It is intentionally kept small and beginner-friendly, but it demonstrates many core Flutter and Firebase concepts.

### Tech Stack
- **Flutter** (latest stable)
- **Firebase Authentication** (Email/Password)
- **Cloud Firestore**
- **REST API** using `http`
- **State Management**: `Provider` + `ChangeNotifier`
- **Navigation**: Named routes, `Drawer`, `BottomNavigationBar`

### Features (High-Level)
- Email/password registration, login, and logout with FirebaseAuth.
- Basic user profile stored in Firestore.
- Announcements list and details stored in Firestore.
- Tasks list and add/edit tasks stored in Firestore.
- Simple home dashboard using bottom navigation.
- Fetch sample data from a public REST API (e.g. JSONPlaceholder) and show it in a list.
- Hero and basic implicit animations (`AnimatedContainer`, `AnimatedOpacity`).
- Loading indicators and basic error handling with `SnackBar`.
- Optional, simple “smart task suggestion” feature (rule-based).

### Project Structure (lib/)
- `main.dart`
- `routes/` – centralized named route configuration
- `screens/` – all UI screens
- `widgets/` – shared widgets (cards, drawers, etc.)
- `services/` – Firebase, REST API and helpers
- `models/` – data models (user, announcement, task, etc.)
- `providers/` – `ChangeNotifier` classes for app state

### Firebase Setup (Required to Run)
1. **Create a Firebase project** in the Firebase console.
2. **Enable Email/Password auth** in the Authentication section.
3. **Create Firestore database** (in test or production mode, as allowed by your course).
4. **Add an iOS and/or Android app** to your Firebase project:
   - For Android, download `google-services.json` and place it under `android/app/`.
   - For iOS, download `GoogleService-Info.plist` and add it to `ios/Runner/`.
5. Add `firebase_core`, `firebase_auth`, and `cloud_firestore` according to `pubspec.yaml` (already added).
6. Run FlutterFire CLI or the official Firebase setup guides to initialize the platforms if needed.

The Flutter code assumes that Firebase has already been configured in the native projects.

### Running the App
```bash
flutter pub get
flutter run
```

You should see the splash screen, then the login/register flow, and finally the main dashboard after logging in.