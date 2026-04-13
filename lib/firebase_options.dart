// AUTO-GENERATED FILE - DO NOT EDIT
// Run `flutterfire configure` to regenerate this file with your Firebase project settings.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC9GM2KBGkuAFU-b3Rgk2z7kQM3Wdi8BvU',
    appId: '1:859523916020:web:501f96004366c1aefffea1',
    messagingSenderId: '859523916020',
    projectId: 'predator-vtest',
    authDomain: 'predator-vtest.firebaseapp.com',
    storageBucket: 'predator-vtest.firebasestorage.app',
    measurementId: 'G-Q00F3J3QDM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDW4SGMxF4As3imHhPH5ivD7jn7Lbab-AA',
    appId: '1:859523916020:android:7264e37bca257878fffea1',
    messagingSenderId: '859523916020',
    projectId: 'predator-vtest',
    storageBucket: 'predator-vtest.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAT64Yusg3DYmPcZ7QHjTyB9C3bAkbGExI',
    appId: '1:859523916020:ios:12f1c04a8e75bb43fffea1',
    messagingSenderId: '859523916020',
    projectId: 'predator-vtest',
    storageBucket: 'predator-vtest.firebasestorage.app',
    iosBundleId: 'com.predator.predator',
  );

}