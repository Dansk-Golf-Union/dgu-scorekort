import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return ios;
    }
    if (Platform.isAndroid) {
      throw UnsupportedError('Android not configured yet');
    }
    throw UnsupportedError('Unsupported platform');
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

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBF5rKJ_ajZD49-znVAQgTtCG4uTvCa4x4',
    appId: '1:822805581464:ios:ac5af92e840566a6f64aed',
    messagingSenderId: '822805581464',
    projectId: 'dgu-scorekort',
    storageBucket: 'dgu-scorekort.firebasestorage.app',
    iosBundleId: 'org.nih.dgupoc',
  );
}

