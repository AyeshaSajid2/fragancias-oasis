//called from home below 2nd header fetches links just its ui is different from link fetch screen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:flutter/material.dart';
import 'package:oasis_fragrances/utils/const.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/user_login.dart';
import '../screens/video_player_screen.dart';

class LinkFetchWidget extends StatelessWidget {
  const LinkFetchWidget({super.key});

  Future<List<Map<String, dynamic>>> _fetchLinks() async {
    try {
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

    if (kIsWeb) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid address')),
        );
      }
    } else {
      if (_isValidYouTubeLink(url)) {
        _navigateToVideoPlayer(url, title, context);
      } else {
        // Navigate to LinkDetailScreen for valid non-YouTube links, passing the title along
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LinkDetailScreen(url: url, title: title),
          ),
        );
      }
    }
  }

  bool _isValidUrl(String url) {
    final Uri? uri = Uri.tryParse(url);
    return uri != null && (uri.hasScheme && uri.hasAuthority);
  }

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

  bool _isValidYouTubeLink(String url) {
    final youtubeRegExp =
        RegExp(r'(https?://)?(www\.)?(youtube|youtu|vimeo)\.(com|be)/.+');
    return youtubeRegExp.hasMatch(url);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: links.length,
              itemBuilder: (context, index) {
                final linkData = links[index];
                String? videoUrl = linkData['link'] ?? '';
                bool hasVideo = videoUrl!.isNotEmpty;
                final title = linkData['title'] ?? 'Untitled Link';

                return GestureDetector(
                  onTap: () {
                    if (hasVideo) {
                      _openLink(videoUrl!, context, title);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid link')),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (linkData['image_url'] != null)
                            Image.network(
                              linkData['image_url'],
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image, size: 50);
                              },
                            ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }
}
