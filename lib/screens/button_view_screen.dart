//Buttons are the links displayed inside the folder. when a button is clicked it navigates to videoplayer screen or web view screen
// screen apears when a specific menu is clicked

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oasis_fragrances/screens/user_login.dart';
import 'package:oasis_fragrances/utils/const.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ButtonScreen extends StatefulWidget {
  final String menuId;
  final String menuName;

  const ButtonScreen({
    super.key,
    required this.menuId,
    required this.menuName,
  });

  @override
  _ButtonScreenState createState() => _ButtonScreenState();
}

class _ButtonScreenState extends State<ButtonScreen> {
  YoutubePlayerController? _youtubePlayerController;
  String? _currentVideoId;
  String _currentLinkName = 'No Video Selected'; // Default message

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.menuName,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          if (_youtubePlayerController != null)
            Column(
              children: [
                YoutubePlayer(
                  controller: _youtubePlayerController!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: AppTheme.primaryColor,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _currentLinkName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('menus')
                  .doc(widget.menuId)
                  .collection('buttons')
                  .orderBy(
                      'sort_order') // Assuming 'buttons' collection for saved buttons
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No buttons saved yet."));
                }

                final buttons = snapshot.data!.docs;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 items per row
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: buttons.length,
                    itemBuilder: (context, index) {
                      var button = buttons[index];
                      String linkUrl = button['link'];
                      String linkName = button['name'] ?? 'Unnamed Button';
                      String? imageUrl = button['imageUrl'];

                      return GestureDetector(
                        onTap: () => _handleLink(context, linkUrl, linkName),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(4, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Display image if available
                              Expanded(
                                child: imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.broken_image,
                                                      size: 36,
                                                      color: Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.image,
                                        size: 36, color: Colors.white),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  linkName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleLink(BuildContext context, String url, String linkName) {
    // Check if the URL is empty or has a valid scheme (http:// or https://)
    if (url.isEmpty || !Uri.parse(url).isAbsolute) {
      // Invalid link
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid link. Please check the URL."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (YoutubePlayer.convertUrlToId(url) != null) {
      // Valid YouTube link
      final videoId = YoutubePlayer.convertUrlToId(url);
      if (videoId != null) {
        setState(() {
          _currentVideoId = videoId;
          _currentLinkName = linkName; // Update the current link name
          _youtubePlayerController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
            ),
          );
        });
      }
    } else {
      // Open link in WebView screen if not a YouTube URL
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LinkDetailScreen(
            url: url,
            title: widget.menuName,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _youtubePlayerController?.dispose();
    super.dispose();
  }
}
