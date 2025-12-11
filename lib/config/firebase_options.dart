import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAiEGQOU4uqTksvLyeofl5AoDePiVjEXcQ',
    authDomain: 'dgu-scorekort.firebaseapp.com',
    projectId: 'dgu-scorekort',
    storageBucket: 'dgu-scorekort.firebasestorage.app',
    messagingSenderId: '822805581464',
    appId: '1:822805581464:web:e13088246716fcc7f64aed',
    measurementId: 'G-QS591GD9JD',
  );
}

