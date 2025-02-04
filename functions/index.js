const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Initialize Firebase Admin SDK
admin.initializeApp();

exports.sendNotification = functions.https.onRequest(async (req, res) => {
  const {fcmToken, title, body} = req.body;

  // Construct the notification message
  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: fcmToken, // FCM Token of the target device
  };

  try {
    // Send the notification using Firebase Admin SDK
    await admin.messaging().send(message);
    res.status(200).send("Notification sent successfully");
  } catch (error) {
    res.status(500).send("Error sending notification: " + error);
  }
});
//cd build/web


//