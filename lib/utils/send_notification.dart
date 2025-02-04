//Main function to send notifications called from send notification screen from admin pannel

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:oasis_fragrances/utils/access_token.dart';

Future<void> sendNotificationToAllUsers(
    String title, String body, String imageUrl, String link) async {
  final String accessToken = await getAccessToken(); // Fetch OAuth token

  final url =
      'https://fcm.googleapis.com/v1/projects/nurture-5d1b7/messages:send';

  final headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $accessToken", // ✅ Pass OAuth token
  };

  final payload = {
    "message": {
      "topic": "all_users", // Send to all users subscribed to the topic
      "notification": {
        "title": title,
        "body": body,
        "image": imageUrl, // Include image in the notification
      },
      "data": {
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "link": link, // Add custom link to data payload
      },
      "android": {
        "priority": "high",
        "notification": {
          "sound": "default",
          "click_action": "FLUTTER_NOTIFICATION_CLICK"
        }
      },
      "apns": {
        "payload": {
          "aps": {
            "sound": "default",
            "mutable-content": 1 // Enable rich notifications for iOS
          }
        },
        "fcm_options": {
          "image": imageUrl, // iOS-specific image configuration
        }
      }
    }
  };

  final response = await http.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(payload),
  );

  if (response.statusCode == 200) {
    print("✅ Notification sent to all users!");
  } else {
    print("❌ Failed to send notification: ${response.statusCode}");
    print("Response: ${response.body}");
  }
}
