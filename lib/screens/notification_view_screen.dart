//screen which appears when notification from drawer is clicked

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oasis_fragrances/screens/user_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/video_player_screen.dart';
import '../utils/const.dart';

class NotificationViewScreen extends StatefulWidget {
  final bool isSpanish;

  const NotificationViewScreen({Key? key, required this.isSpanish})
      : super(key: key);

  @override
  _NotificationViewScreenState createState() => _NotificationViewScreenState();
}

class _NotificationViewScreenState extends State<NotificationViewScreen> {
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedNotifications =
        prefs.getStringList('notifications') ?? [];

    setState(() {
      notifications = storedNotifications
          .map((item) {
            return Map<String, dynamic>.from(jsonDecode(item));
          })
          .toList()
          .reversed
          .toList(); // Reverse to show newest first
    });
  }

  void _handleNotificationClick(String? url, String title) {
    if (url != null && Uri.tryParse(url)?.hasAbsolutePath == true) {
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoUrl: url,
              videoTitle: title,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LinkDetailScreen(
              url: url,
              title: title,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid link. Cannot open.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle =
        widget.isSpanish ? 'Notificaciones recientes' : 'Recent Notifications';
    String noNotificationsMessage = widget.isSpanish
        ? '¡No hay notificaciones aún!'
        : 'No notifications yet!';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.secondaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: notifications.isEmpty
          ? Center(
              child:
                  Text(noNotificationsMessage, style: TextStyle(fontSize: 18)))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(index);
              },
            ),
    );
  }

  Widget _buildNotificationCard(int index) {
    final notification = notifications[index];
    final String title = notification["title"] ?? "No Title";
    final String body = notification["body"] ?? "No Body";
    final String? imageUrl = notification["image"];
    final String? link = notification["link"];

    return GestureDetector(
      onTap: () => _handleNotificationClick(link, title),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(4, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                body,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 8),
              if (imageUrl != null && imageUrl.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image,
                            size: 50, color: Colors.grey);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
