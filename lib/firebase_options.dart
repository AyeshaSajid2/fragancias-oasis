// File generated by FlutterFire CLI.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyA4IuY2ToygugFD1nt7EZAP3tMEV3SxoLc',
    appId: '1:837066592546:web:cb6387f7ab2ab98a11d57b',
    messagingSenderId: '837066592546',
    projectId: 'nurture-5d1b7',
    authDomain: 'nurture-5d1b7.firebaseapp.com',
    storageBucket: 'nurture-5d1b7.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAIqZIKzAUU0ZPB-u0X3lORuu_90RbPjrw',
    appId: '1:837066592546:android:9678642c77b0482a11d57b',
    messagingSenderId: '837066592546',
    projectId: 'nurture-5d1b7',
    storageBucket: 'nurture-5d1b7.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDFqy51xcRSzoGfyeKDOJpZ3x3qdnpUoPs',
    appId: '1:837066592546:ios:e3d3aeeefe2dbd0c11d57b',
    messagingSenderId: '837066592546',
    projectId: 'nurture-5d1b7',
    storageBucket: 'nurture-5d1b7.appspot.com',
    iosBundleId: 'com.company.fraganciasOasis',
  );
}
