//Menus page

import 'package:flutter/material.dart';
import 'package:oasis_fragrances/screens/notification_view_screen.dart';
import 'package:oasis_fragrances/utils/const.dart';

import '../auth/admin_auth/admin_login_screen.dart';
import '../screens/contact_details_screen.dart';
import '../screens/social_links_view_screen.dart';
import '../screens/user_login.dart';
import '../screens/video_fetch_screen.dart';

class MyCustomDrawer extends StatefulWidget {
  final Function(String) setLocale;
  final bool isSpanish;
  final VoidCallback switchLanguage;

  const MyCustomDrawer(
      {Key? key,
      required this.setLocale,
      required this.isSpanish,
      required this.switchLanguage})
      : super(key: key);

  @override
  _MyCustomDrawerState createState() => _MyCustomDrawerState();
}

class _MyCustomDrawerState extends State<MyCustomDrawer> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Drawer(
          child: Stack(
            children: [
              ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  // Language Switcher at the top of the drawer
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isSpanish ? 'Español' : 'English',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        Switch(
                          value: widget.isSpanish,
                          onChanged: (value) {
                            widget.switchLanguage();
                          },
                          activeColor: AppTheme.secondaryColor,
                          inactiveThumbColor: Colors.grey,
                        ),
                      ],
                    ),
                  ),

                  const DrawerHeader(
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                    ),
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),

                  _buildDrawerItem(
                    context,
                    icon: Icons.login,
                    text: widget.isSpanish
                        ? 'Iniciar sesión'
                        : 'Login', // Update the text based on language
                    onTap: () {
                      const url =
                          'https://fraganciasoasis.com/pr/tienda/fraganciasoasis/login';

                      // Pass the title in Spanish or English based on the language setting
                      String pageTitle =
                          widget.isSpanish ? 'Iniciar sesión' : 'Login';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LinkDetailScreen(url: url, title: pageTitle),
                        ),
                      );
                    },
                  ),

                  _buildDrawerItem(
                    context,
                    icon: Icons.share,
                    text: widget.isSpanish ? 'Compartir' : 'Share',
                    onTap: () {},
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.video_library,
                    text: widget.isSpanish ? 'Videos' : 'Videos',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VideoFetchScreen(isSpanish: widget.isSpanish),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.contact_mail,
                    text: widget.isSpanish ? 'Contáctanos' : 'Contact Us',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ContactDetailsScreen(isSpanish: widget.isSpanish),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.notifications,
                    text: widget.isSpanish ? 'Notificaciones' : 'Notifications',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationViewScreen(
                            isSpanish: widget.isSpanish,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.link,
                    text:
                        widget.isSpanish ? 'Enlaces Sociales' : 'Social Links',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FetchSocialLinks(
                            isSpanish: widget.isSpanish,
                          ), // or false
                        ),
                      );
                    },
                  ),
                ],
              ),
              Positioned(
                bottom: -10,
                right: constraints.maxWidth * 0.02,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminLoginScreen(
                            setLocale: widget.setLocale), // Pass setLocale here
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/logo.png', // Path to your logo
                    width: constraints.maxWidth * 0.2,
                    height: constraints.maxWidth * 0.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.secondaryColor),
      title: Text(
        text,
        style: const TextStyle(color: AppTheme.secondaryColor),
      ),
      onTap: onTap,
    );
  }
}
