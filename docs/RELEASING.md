# Releasing

Checklist for publishing the app (for example to Google Play).

## 1. Make the app yours
- Replace the placeholder application id `com.example.campus_companion` in
  `android/app/build.gradle*` and the Android manifest with your own reverse-domain id.
- Set `version` in `pubspec.yaml` (`1.0.0+1`; the number after `+` must grow with every upload).

## 2. Sign the release build
- Create an upload keystore once and **keep it out of git**:
  `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- Reference it from an untracked `android/key.properties` and read it in `android/app/build.gradle*`.
- Back the keystore and its passwords up somewhere safe; losing them blocks future updates.

## 3. Point the app at a hosted Supabase
- Follow *Use your own Supabase project* in the README (migrations, email templates, SMTP,
  `admin-delete-user` function).
- Build with your values: `flutter build appbundle --release --dart-define-from-file=env.json`.
- Release builds block plain HTTP, so the backend URL must be `https://`.

## 4. Harden before launch
- Turn on *Confirm email* and the password rules in Supabase Auth, and use a real SMTP sender.
- Restrict API usage and enable the captcha if you expect public sign-ups.
- Free Supabase projects pause after about a week of inactivity; use a paid plan or a
  scheduled keep-alive request for anything user-facing.
- Run `flutter analyze`, `flutter test` and `supabase test db` and check the CI is green.
- Publish a privacy policy; Google Play requires one.
