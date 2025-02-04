// screen which appears when arrow of 2nd error is clicked
// links are stored by upload link screen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oasis_fragrances/screens/user_login.dart';
import 'package:oasis_fragrances/utils/const.dart';
import 'package:url_launcher/url_launcher.dart';

import 'video_player_screen.dart'; // Import the video player screen

class LinkFetchScreen extends StatefulWidget {
  final String heading2;

  const LinkFetchScreen(this.heading2, {super.key});

  @override
  _LinkFetchScreenState createState() => _LinkFetchScreenState();
}

class _LinkFetchScreenState extends State<LinkFetchScreen> {
  Future<List<Map<String, dynamic>>> _fetchLinks() async {
    try {
      // Fetch and sort by 'sort_order' ascending
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('links')
          .orderBy('sort_order', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error fetching links: $e');
      return [];
    }
  }

  void _openLink(String url, BuildContext context, String title) async {
    if (!_isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid link')),
      );
      return;
    }

    final Uri uri = Uri.parse(url);

    if (_isValidYouTubeLink(url)) {
      // Navigate to video player screen
      _navigateToVideoPlayer(url, title, context);
    } else if (await canLaunchUrl(uri)) {
      // Navigate to details screen for valid web links
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LinkDetailScreen(
            url: url,
            title: title, // Pass the title to the LinkDetailScreen
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid address')),
      );
    }
  }

  // Function to navigate to the video player screen
  void _navigateToVideoPlayer(
      String videoUrl, String title, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VideoPlayerScreen(videoUrl: videoUrl, videoTitle: title),
      ),
    );
  }

  // Function to check if the link is a valid YouTube link
  bool _isValidYouTubeLink(String url) {
    final youtubeRegExp =
        RegExp(r'(https?://)?(www\.)?(youtube|youtu|vimeo)\.(com|be)/.+');
    return youtubeRegExp.hasMatch(url);
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.heading2, // Use widget to access the passed heading text
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchLinks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error fetching links'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No links found'));
          } else {
            final links = snapshot.data!;
            return ListView.builder(
              itemCount: links.length,
              itemBuilder: (context, index) {
                final linkData = links[index];
                String? videoUrl = linkData['link'] ?? '';
                bool hasVideo = videoUrl!.isNotEmpty;

                return InkWell(
                  onTap: () {
                    if (hasVideo) {
                      _openLink(
                          videoUrl, context, linkData['title'] ?? 'Video');
                    } else {
                      _openLink(videoUrl, context, linkData['title'] ?? 'Link');
                    }
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Image section
                          if (linkData['image_url'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                linkData['image_url'],
                                fit: BoxFit.cover,
                                height: 100,
                                width: 100,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.broken_image,
                                      size: 50);
                                },
                              ),
                            ),
                          const SizedBox(width: 16),
                          // Text content section
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (linkData['title'] != null)
                                  Text(
                                    linkData['title']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  linkData['link'] ?? 'No link available',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
