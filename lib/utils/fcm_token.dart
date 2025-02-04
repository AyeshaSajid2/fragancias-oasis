//fcm token needed to send firebase cloud notification

import 'package:firebase_messaging/firebase_messaging.dart';

Future<String?> getFCMToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  String? token = await messaging.getToken();

  if (token != null) {
    print("FCM Registration Token: $token");
  } else {
    print("Failed to get FCM token");
  }

  return token;
}
