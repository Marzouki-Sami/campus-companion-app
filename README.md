# Campus Companion

A cross-platform campus app built with **Flutter** and **Firebase**. Students, professors and administrators share announcements, manage personal tasks and administer users through role-based access control enforced by Firestore security rules.

## Features

| Area | Highlights |
| --- | --- |
| Authentication | Email/password sign-up and sign-in, profile editing, account suspension |
| Announcements | Create, edit and delete (professors and admins); category filters, date range, full-text search |
| Tasks | Personal task list with due dates, overdue highlighting, done/not-done filters and search |
| Administration | User management (roles, suspension), category management, platform statistics |

## Tech stack

- Flutter 3.x / Dart 3.x, Material 3
- Firebase Authentication and Cloud Firestore
- State management: `provider` (`ChangeNotifier`)
- Security: role-based Firestore rules (`firestore.rules`)

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.24 or newer
- A Firebase project with **Email/Password** authentication and **Cloud Firestore** enabled
- [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup): `dart pub global activate flutterfire_cli`

### Setup

```bash
git clone https://github.com/Marzouki-Sami/campus-companion-app.git
cd campus-companion-app
flutter pub get

# Generates lib/firebase_options.dart and the platform config files (all git-ignored)
flutterfire configure

flutter run
```

Firebase configuration is intentionally **not** committed. Template files (`*.example`) show the expected shape of `google-services.json`, `GoogleService-Info.plist` and `firebase_options.dart`.

### Deploy the security rules

```bash
firebase deploy --only firestore:rules
```

The rules live in [`firestore.rules`](firestore.rules). New accounts are always created as `student`; promote a user to `professor` or `admin` by editing the `role` field of their `users/{uid}` document in the Firebase console (or from the admin dashboard once you have an admin).

## Roles

| Role | Announcements | Tasks | Categories | Users |
| --- | --- | --- | --- | --- |
| Student | read | own | read | own profile |
| Professor | read / write | own | read | own profile |
| Admin | read / write | own | read / write | read / write |

## Build

```bash
flutter build apk --release
```

## License

Released under the [MIT License](LICENSE).
