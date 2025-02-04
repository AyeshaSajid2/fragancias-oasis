//This function is used to acces the token to send notifications to all devices

import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart'; // ✅ Correct import
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

Future<String> getAccessToken() async {
  // Load service account JSON file
  final serviceAccountJson = await rootBundle.loadString(
      'assets/nurture-5d1b7-2fb6114c2365.json'); // Ensure correct file path

  // Parse the credentials
  final serviceAccount =
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson);

  // Get authenticated client using `auth_io.dart`
  final client = await clientViaServiceAccount(serviceAccount, [
    "https://www.googleapis.com/auth/firebase.messaging", // OAuth Scope
  ]);

  // Extract the access token
  return client.credentials.accessToken.data;
}
