# Releasing

Checklist for publishing the app (for example to Google Play).

## 1. Make the app yours
- Replace the placeholder application id `com.example.campus_companion` in
  `android/app/build.gradle.kts` and the Android manifest with your own reverse-domain id.
- Set `version` in `pubspec.yaml` (`1.0.0+1`; the number after `+` must grow with every upload).

## 2. Sign the release build
- Create an upload keystore once and **keep it out of git**:
  `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- Reference it from an untracked `android/key.properties` and read it in `android/app/build.gradle.kts`.
- Back the keystore and its passwords up somewhere safe; losing them blocks future updates.

## 3. Point the app at a hosted Supabase
- Follow *Use your own Supabase project* in the README: `supabase db push` applies every migration
  (schema, photo bucket and its policies, events, pins and read state, reminders), then deploy the
  `admin-delete-user` function, set the email templates and a real SMTP sender.
- Check in the dashboard that the `announcement-images` bucket exists (5 MB, JPEG/PNG/WebP). It is
  public-read; switch it to private and serve signed URLs if announcements are sensitive.
- First admin: `update profiles set role = 'admin' where email = 'you@example.com';`
- Build with your values: `flutter build appbundle --release --dart-define-from-file=env.json`.
- Release builds block plain HTTP, so the backend URL must be `https://`.

## 4. Harden before launch
- Turn on *Confirm email* and the password rules in Supabase Auth, and use a real SMTP sender.
- Enable the captcha (Cloudflare Turnstile) if you expect public sign-ups: put the secret key in
  Supabase and `TURNSTILE_SITE_KEY` in `env.json`.
- Task reminders need the notification permission. Android 13+ asks the first time a user sets a
  reminder; the manifest already declares the permission and the boot receiver.
- Free Supabase projects pause after about a week of inactivity; use a paid plan, or add the
  repository secrets `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` so the
  [keep-alive workflow](../.github/workflows/keep-alive.yml) pings the project twice a week.
- Run `flutter analyze`, `flutter test` and `supabase test db` and check the CI is green (including
  the docker-compose smoke test and the secret scan).
- Restrict any old Firebase API key from this project's history in the Google Cloud console; it is
  no longer used.
- Publish a privacy policy; Google Play requires one.

## 5. Store listing
- The screenshots in `docs/screenshots` use generated demo data. For store assets, capture your own
  from a phone running demo data, and never include your photo gallery or notification bar.

## Known limits
- Changes made offline are not queued.
- Announcement photos are not saved for offline viewing; a placeholder is shown.