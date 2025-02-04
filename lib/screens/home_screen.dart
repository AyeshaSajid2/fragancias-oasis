//users home screen

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oasis_fragrances/screens/button_view_screen.dart';
import 'package:oasis_fragrances/screens/link_fetch_screen.dart';
import 'package:oasis_fragrances/screens/menu_view_screen.dart';
import 'package:oasis_fragrances/utils/const.dart';
import 'package:oasis_fragrances/widgets/drawer.dart';
import 'package:oasis_fragrances/widgets/links.dart';
import 'package:oasis_fragrances/widgets/menu_widget.dart';

import '../widgets/heading_widget.dart';

class HomeScreen extends StatefulWidget {
  final Function(String) setLocale; // Specify the type as Function(String)

  const HomeScreen({super.key, required this.setLocale});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> imageUrls = [];
  bool isSpanish = false;
  String heading1 = "Menu"; // Default value for heading 1
  String heading2 = "Links"; // Default value for heading 2

  @override
  void initState() {
    super.initState();
    _fetchCrousalImages(); // Fetch images from Firestore on startup
    _loadHeadings(); // Load headings from Firestore
  }

  // Function to fetch images from Firebase
  Future<void> _fetchCrousalImages() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('crousal_images').get();
      setState(() {
        imageUrls =
            snapshot.docs.map((doc) => doc['imageUrl'] as String).toList();
      });
    } catch (e) {
      print("Error fetching images: $e");
    }
  }

  // Function to load headings from Firestore
  Future<void> _loadHeadings() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('headings')
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs[0];
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          heading1 = data['heading1'] ?? "Menu"; // Default if not found
          heading2 = data['heading2'] ?? "Links"; // Default if not found
        });
      }
    } catch (e) {
      print("Error loading headings: $e");
    }
  }

  // Function to switch language
  void _switchLanguage() {
    setState(() {
      isSpanish = !isSpanish;
    });
    widget.setLocale(isSpanish ? 'es' : 'en'); // Change language
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryColor,
        title: Text(
          isSpanish ? 'Inicio' : 'Home',
          style: const TextStyle(color: Colors.white),
        ),
      ),

      drawer: MyCustomDrawer(
          setLocale: widget.setLocale,
          isSpanish: isSpanish,
          switchLanguage: _switchLanguage), // Pass setLocale and switchLanguage
      body: RefreshIndicator(
        onRefresh: _fetchCrousalImages, // Reload content on pull
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              imageUrls.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    )
                  : CarouselSlider.builder(
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index, realIndex) {
                        final imageUrl = imageUrls[index];
                        return Image.network(imageUrl, fit: BoxFit.cover);
                      },
                      options: CarouselOptions(
                        height: 200,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        aspectRatio: 16 / 9,
                        viewportFraction: 1.0,
                      ),
                    ),
              const SizedBox(height: 16),
              HeadingWithArrow(
                headingText: heading1, // Dynamically loaded heading
                onArrowClick: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuViewScreen(heading1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.25,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('menus')
                      .orderBy('sort_order')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No menus available."));
                    }

                    final menus = snapshot.data!.docs;

                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: menus.map((menu) {
                        double screenWidth = MediaQuery.of(context).size.width;
                        double squareSize = screenWidth * 0.4;

                        return Container(
                          width: squareSize,
                          height: squareSize,
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: const Offset(4, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: MenuWidget(
                              menuName: menu['menu_name'],
                              menuImage: menu['menu_image'],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ButtonScreen(
                                      menuId: menu.id,
                                      menuName: menu['menu_name'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              HeadingWithArrow(
                headingText: heading2, // Dynamically loaded heading
                onArrowClick: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LinkFetchScreen(heading2), // Passing headingText
                    ),
                  );
                },
              ),
              LinkFetchWidget()
            ],
          ),
        ),
      ),
    );
  }
}
