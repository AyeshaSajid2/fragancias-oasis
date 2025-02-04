import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oasis_fragrances/admin_files/admin_list.dart';
import 'package:oasis_fragrances/admin_files/edit_social_link.dart';
import 'package:oasis_fragrances/admin_files/save_heading_screen.dart';
import 'package:oasis_fragrances/admin_files/upload_link_screen.dart';
import 'package:oasis_fragrances/admin_files/video_upload.dart';
import 'package:oasis_fragrances/auth/admin_auth/admin_login_screen.dart';
import 'package:oasis_fragrances/utils/const.dart';

import 'contact_detail.dart';
import 'send_notifications.dart';
import 'image_picker.dart';
import 'menu_upload_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final Function(String) setLocale; // Added setLocale parameter

  const AdminHomeScreen({super.key, required this.setLocale});

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String timeText = "";
  String dateText = "";
  bool _isEnglish = true; // Language toggle state

  String formatCurrentLiveTime(DateTime time) {
    return DateFormat("hh:mm:ss a").format(time);
  }

  String formatCurrentDate(DateTime date) {
    return DateFormat("dd MMMM, yyyy").format(date);
  }

  void getCurrentLiveTime() {
    final DateTime timeNow = DateTime.now();
    final String liveTime = formatCurrentLiveTime(timeNow);
    final String liveDate = formatCurrentDate(timeNow);

    if (mounted) {
      setState(() {
        timeText = liveTime;
        dateText = liveDate;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    timeText = formatCurrentLiveTime(DateTime.now());
    dateText = formatCurrentDate(DateTime.now());

    Timer.periodic(const Duration(seconds: 1), (timer) {
      getCurrentLiveTime();
    });
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Exit'),
            content:
                const Text('Do you really want to sign out and exit the app?'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Don't exit
                },
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (c) => AdminLoginScreen(
                              setLocale: widget.setLocale, //
                            )), // Placeholder for actual exit action
                  );
                },
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _toggleLanguage() {
    setState(() {
      _isEnglish = !_isEnglish;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 600;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            color: AppTheme.secondaryColor,
          ),
          title: Text(
            _isEnglish ? "Admin Web Portal" : "Portal Web del Administrador",
            style: const TextStyle(
              fontSize: 20,
              letterSpacing: 3,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color.fromRGBO(210, 217, 223, 1),
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(size.width * 0.03),
                    child: Text(
                      "$timeText\n$dateText",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isWideScreen ? 24 : 18,
                        color: Colors.black,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Language Toggle Button
                  Padding(
                    padding: EdgeInsets.only(top: size.height * 0.03),
                    child: ElevatedButton(
                      onPressed: _toggleLanguage,
                      child: Text(
                        _isEnglish ? "Switch to Spanish" : "Cambiar a Inglés",
                        style: TextStyle(
                          fontSize: isWideScreen ? 18 : 14,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(size.width * 0.03),
                        backgroundColor: AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  // Buttons Section
                  Wrap(
                    spacing: size.width * 0.03,
                    runSpacing: size.width * 0.03,
                    alignment: WrapAlignment.center,
                    children: _buildButtons(size, context),
                  ),
                  // Logout Button
                  Padding(
                    padding: EdgeInsets.only(top: size.height * 0.05),
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isEnglish ? "Logout" : "Cerrar sesión",
                        style: TextStyle(
                          fontSize: isWideScreen ? 18 : 14,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(size.width * 0.03),
                        backgroundColor: AppTheme.secondaryColor,
                      ),
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (c) => AdminLoginScreen(
                                    setLocale: widget.setLocale,
                                  ) // Instance call
                              ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildButtons(Size size, BuildContext context) {
    final List<Map<String, dynamic>> buttonData = [
      {
        "label": _isEnglish
            ? "Update Carousel Images"
            : "Actualizar imágenes de carrusel",
        "icon": Icons.image,
        "onPress": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => UpdateCrousalImageScreen(
                isSpanish: !_isEnglish, // Fix: Toggle language correctly
              ),
            ),
          );
        },
      },
      {
        "label":
            _isEnglish ? "Update Social Links" : "Actualizar enlaces sociales",
        "icon": Icons.link,
        "onPress": () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (c) => EditSocialLinksScreen(
                        isSpanish: !_isEnglish,
                      ))); // Social link edit
        },
      },
      {
        "label": _isEnglish ? "Upload Menu" : "Subir menú",
        "icon": Icons.folder,
        "onPress": () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (c) => UploadMenuScreen(
                        isSpanish: !_isEnglish,
                      ))); // Upload menu
        },
      },
      {
        "label": _isEnglish ? "Upload headers " : "Subir encabezados",
        "icon": Icons.title,
        "onPress": () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (c) => SaveHeadingsScreen(
                        isSpanish: !_isEnglish,
                      ))); // Upload headings
        },
      },
      {
        "label": _isEnglish ? "Upload Links " : "Subir enlaces",
        "icon": Icons.title,
        "onPress": () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (c) => UploadLinksScreen(
                        isSpanish: !_isEnglish,
                      ))); // Upload headings
        },
      },
      {
        "label": _isEnglish ? "Upload Videos" : "Subir videos",
        "icon": Icons.video_library,
        "onPress": () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (c) => UploadVideoScreen(
                        isSpanish: !_isEnglish,
                      ))); // Upload videos
        },
      },
      {
        "label": _isEnglish ? "Send Notifications" : "Enviar notificaciones",
        "icon": Icons.notifications,
        "onPress": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => SendNotificationScreen(
                isSpanish:
                    !_isEnglish, // Pass the correct value based on the current language
              ),
            ),
          );
        },
      },
      {
        "label": _isEnglish ? "Admins" : "Administradores",
        "icon": Icons.admin_panel_settings,
        "onPress": () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (c) => AdminListScreen(
                        setLocale: widget.setLocale,
                        isSpanish: !_isEnglish,
                      ))); // Admin list
        },
      },
      {
        "label": _isEnglish
            ? "Update Contact Details"
            : "Actualizar detalles de contacto",
        "icon": Icons.contact_phone,
        "onPress": () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (c) => UpdateContactScreen(
                        isSpanish: !_isEnglish,
                      ))); // Contact details
        },
      },
    ];

    return buttonData.map((data) {
      return ElevatedButton.icon(
        icon: Icon(
          data["icon"],
          color: Colors.white,
        ),
        label: Text(
          data["label"],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size.width > 600 ? 16 : 12,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(size.width * 0.02),
          backgroundColor: AppTheme.secondaryColor,
        ),
        onPressed: data["onPress"],
      );
    }).toList();
  }
}
