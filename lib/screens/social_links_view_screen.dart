//Screen which appears when social liks is pressed from drawer

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:oasis_fragrances/screens/user_login.dart';
import 'package:oasis_fragrances/utils/const.dart';

import '../widgets/video_card.dart';

class FetchSocialLinks extends StatelessWidget {
  final bool isSpanish;

  const FetchSocialLinks({Key? key, required this.isSpanish}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSpanish ? "Enlaces Sociales" : "Social Links",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.secondaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Container(
                padding: EdgeInsets.all(16),
                constraints: BoxConstraints(
                    maxWidth: 600), // Limit width for large screens
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('social_links')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          isSpanish
                              ? 'No hay información disponible.'
                              : 'No info available.',
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> data = snapshot.data!.docs[index]
                            .data() as Map<String, dynamic>;
                        return ContactCard(
                            data: data, context: context, isSpanish: isSpanish);
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ContactCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final BuildContext context;
  final bool isSpanish;

  const ContactCard(
      {Key? key,
      required this.data,
      required this.context,
      required this.isSpanish})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContainer(
                'facebook.svg', 'Facebook', 'Facebook', data['Facebook']),
            _buildContainer(
                'instagram.svg', 'Instagram', 'Instagram', data['Instagram']),
            _buildContainer(
                'linkedin.svg', 'LinkedIn', 'LinkedIn', data['LinkedIn']),
            _buildContainer(
                'pinterest.svg', 'Pinterest', 'Pinterest', data['Pinterest']),
            _buildContainer('tiktok.svg', 'TikTok', 'TikTok', data['TikTok']),
            _buildContainer(
                'twitter.svg', 'Twitter', 'Twitter', data['Twitter']),
            _buildContainer(
                'youtube.svg', 'YouTube', 'YouTube', data['YouTube']),
          ],
        ),
      ),
    );
  }

  Widget _buildContainer(
      String iconAsset, String labelEn, String labelEs, String? value) {
    String label = isSpanish ? labelEs : labelEn; // Choose language
    return GestureDetector(
      onTap: () {
        if (value != null && value.isNotEmpty) {
          _launchURL(value, context);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/social/$iconAsset',
              height: 24,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label: ${value ?? 'N/A'}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to launch the URL in the appropriate app
  Future<void> _launchURL(String url, BuildContext context) async {
    if (url.contains("youtube.com") || url.contains("youtu.be")) {
      // Open YouTube link in VideoPlayerScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(videoUrl: url),
        ),
      );
    } else if (Uri.tryParse(url)?.hasAbsolutePath == true) {
      // Open other web links in LinkDetailScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LinkDetailScreen(
            url: url,
            title: '',
          ),
        ),
      );
    } else {
      // Show error if URL is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSpanish
              ? 'Enlace no válido. No se puede abrir.'
              : 'Invalid link. Cannot open.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
