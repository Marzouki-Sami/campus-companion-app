// TEMPLATE. Run `flutterfire configure` to generate lib/firebase_options.dart (git-ignored).
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_APIKEY',
    appId: 'YOUR_APPID',
    messagingSenderId: 'YOUR_MESSAGINGSENDERID',
    projectId: 'YOUR_PROJECTID',
    authDomain: 'YOUR_AUTHDOMAIN',
    storageBucket: 'YOUR_STORAGEBUCKET',
    measurementId: 'YOUR_MEASUREMENTID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_APIKEY',
    appId: 'YOUR_APPID',
    messagingSenderId: 'YOUR_MESSAGINGSENDERID',
    projectId: 'YOUR_PROJECTID',
    storageBucket: 'YOUR_STORAGEBUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_APIKEY',
    appId: 'YOUR_APPID',
    messagingSenderId: 'YOUR_MESSAGINGSENDERID',
    projectId: 'YOUR_PROJECTID',
    storageBucket: 'YOUR_STORAGEBUCKET',
    iosBundleId: 'YOUR_IOSBUNDLEID',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_APIKEY',
    appId: 'YOUR_APPID',
    messagingSenderId: 'YOUR_MESSAGINGSENDERID',
    projectId: 'YOUR_PROJECTID',
    storageBucket: 'YOUR_STORAGEBUCKET',
    iosBundleId: 'YOUR_IOSBUNDLEID',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_APIKEY',
    appId: 'YOUR_APPID',
    messagingSenderId: 'YOUR_MESSAGINGSENDERID',
    projectId: 'YOUR_PROJECTID',
    authDomain: 'YOUR_AUTHDOMAIN',
    storageBucket: 'YOUR_STORAGEBUCKET',
    measurementId: 'YOUR_MEASUREMENTID',
  );
}
