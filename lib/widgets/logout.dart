//logout widget to logout the admin

import 'package:flutter/material.dart';

class Logout {
  Future<void> exitDialoge(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are you sure?"),
          content: Text("Do you want to log out?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Add your sign-out logic here
                Navigator.of(context).pop();
              },
              child: Text("Logout"),
            ),
          ],
        );
      },
    );
  }
}
