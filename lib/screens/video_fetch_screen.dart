//screen which is called when video from the menu is called

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oasis_fragrances/screens/video_player_screen.dart';

import '../utils/const.dart';

class VideoFetchScreen extends StatelessWidget {
  final bool isSpanish;

  const VideoFetchScreen({Key? key, required this.isSpanish}) : super(key: key);

  // Function to check if the URL is a valid YouTube link
  bool _isValidYouTubeLink(String url) {
    final youtubeRegExp =
        RegExp(r'(https?://)?(www\.)?(youtube|youtu|vimeo)\.(com|be)/.+');
    return youtubeRegExp.hasMatch(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            isSpanish ? 'Videos' : 'Videos',
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
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('videos')
              .orderBy('sort_order') // Add ordering by sort_order
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final videos = snapshot.data!.docs;

            if (videos.isEmpty) {
              return Center(
                child: Text(
                  isSpanish
                      ? 'No hay videos disponibles'
                      : 'No videos available',
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  final videoUrl =
                      video['link']; // Ensure the 'link' field is correct
                  final videoTitle = video['title'];

                  print('Fetched video URL: $videoUrl'); // Debugging output

                  return GestureDetector(
                    onTap: () {
                      print(
                          'Video URL: $videoUrl'); // Print the URL to check its format

                      if (_isValidYouTubeLink(videoUrl)) {
                        // If the URL is valid, navigate to the VideoPlayerScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              videoUrl: videoUrl,
                              videoTitle: videoTitle,
                            ),
                          ),
                        );
                      } else {
                        // Handle invalid YouTube URL case
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(isSpanish
                                  ? 'URL de YouTube no válida'
                                  : 'Invalid YouTube URL')),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16.0),
                              topRight: Radius.circular(16.0),
                            ),
                            child: Image.network(
                              video['imageUrl'],
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              video['title'],
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
        ));
  }
}
