import 'package:firebase_core/firebase_core.dart'
    show
        FirebaseOptions;
import 'package:flutter/foundation.dart'
    show
        defaultTargetPlatform,
        kIsWeb,
        TargetPlatform;

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
    apiKey: 'AIzaSyDL3TV6EAic3YwAMXdokJiSM_wAlELuM7E',
    appId: '1:311633193180:web:3d8bba36653c1047122c19',
    messagingSenderId: '311633193180',
    projectId: 'produceaiq',
    authDomain: 'produceaiq.firebaseapp.com',
    storageBucket: 'produceaiq.firebasestorage.app',
    measurementId: 'G-2L52JJ1GZ2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB4cf5mJnVtyH-Qv8g8COye0hFgiEEwtM4',
    appId: '1:311633193180:android:4cab44311eded6bf122c19',
    messagingSenderId: '311633193180',
    projectId: 'produceaiq',
    storageBucket: 'produceaiq.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCjs8V5aQGooiujURSiixjmYmrVK4moTYQ',
    appId: '1:311633193180:ios:4d869191f3de9141122c19',
    messagingSenderId: '311633193180',
    projectId: 'produceaiq',
    storageBucket: 'produceaiq.firebasestorage.app',
    iosBundleId: 'com.example.produceaiq',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCjs8V5aQGooiujURSiixjmYmrVK4moTYQ',
    appId: '1:311633193180:ios:4d869191f3de9141122c19',
    messagingSenderId: '311633193180',
    projectId: 'produceaiq',
    storageBucket: 'produceaiq.firebasestorage.app',
    iosBundleId: 'com.example.produceaiq',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDL3TV6EAic3YwAMXdokJiSM_wAlELuM7E',
    appId: '1:311633193180:web:a6edbbf1687d652e122c19',
    messagingSenderId: '311633193180',
    projectId: 'produceaiq',
    authDomain: 'produceaiq.firebaseapp.com',
    storageBucket: 'produceaiq.firebasestorage.app',
    measurementId: 'G-4YQ83GN61T',
  );
}
