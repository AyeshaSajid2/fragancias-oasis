import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oasis_fragrances/admin_files/admin_home_screen.dart';

import '../../screens/home_screen.dart';
import '../../utils/const.dart';

class AdminLoginScreen extends StatefulWidget {
  final Function(String) setLocale; // Added setLocale parameter

  const AdminLoginScreen(
      {super.key, required this.setLocale}); // Constructor with setLocale

  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  String adminEmail = "";
  String adminPassword = "";
  late AnimationController _controller;
  late Animation<Offset> _animation;
  bool isSpanish = false; // Add this flag to toggle language

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0.05, 0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );
  }

  void _triggerVibration() {
    HapticFeedback.vibrate();
    _controller.forward().then((value) => _controller.reverse());
  }

  allowAdminToLogin() async {
    if (adminEmail.isEmpty || adminPassword.isEmpty) {
      _triggerVibration();
      _showSnackBar(
        isSpanish
            ? "Campo requerido vacío. Por favor, complete todos los campos."
            : "Required entity is empty. Please fill in all fields.",
        Colors.red,
      );
      return;
    }

    SnackBar snackBar = SnackBar(
      content: Text(
        isSpanish
            ? "Comprobando credenciales, por favor espere..."
            : "Checking Credentials, Please wait...",
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
      backgroundColor: AppTheme.accentColor,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    User? currentAdmin;

    try {
      final fAuth = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      currentAdmin = fAuth.user;

      if (currentAdmin != null) {
        final snap = await FirebaseFirestore.instance
            .collection("admins")
            .doc(currentAdmin.uid)
            .get();

        if (snap.exists) {
          // Navigate to Admin Home Screen and pass locale and setLocale as parameters
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => AdminHomeScreen(
                setLocale: widget.setLocale, //
                // Set your required locale here// Pass setLocale
              ),
            ),
          );
        } else {
          _showSnackBar(
              isSpanish
                  ? "No se encontró registro, no eres un administrador."
                  : "No record found, you are not an admin.",
              Colors.black);
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'network-request-failed') {
        errorMessage = isSpanish
            ? "Error de red. Por favor, verifica tu conexión a Internet."
            : "Network error. Please check your internet connection.";
      } else if (e.code == 'user-not-found') {
        errorMessage = isSpanish
            ? "No se encontró administrador con este correo electrónico."
            : "No admin found with this email.";
      } else if (e.code == 'wrong-password') {
        errorMessage = isSpanish
            ? "Contraseña incorrecta. Inténtalo nuevamente."
            : "Incorrect password. Please try again.";
      } else if (e.code == 'invalid-email') {
        errorMessage = isSpanish
            ? "Formato de correo electrónico inválido."
            : "Invalid email format.";
      } else {
        errorMessage = isSpanish
            ? "Ocurrió un error inesperado: ${e.message}"
            : "An unexpected error occurred: ${e.message}";
      }
      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      _showSnackBar(
          isSpanish
              ? "Ocurrió un error. Por favor, intenta nuevamente."
              : "An error occurred. Please try again.",
          Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
      backgroundColor: color,
      duration: const Duration(seconds: 5),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async {
        // Navigate to the HomeScreen when the back button is pressed and pass setLocale
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              setLocale: widget.setLocale, // Pass setLocale
            ),
          ),
        );
        return false; // Prevent the default back navigation
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            bool isWeb = constraints.maxWidth > 600;
            return Center(
              child: Container(
                width: isWeb ? screenWidth * 0.4 : screenWidth * 0.9,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Language Toggle Button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(
                          isSpanish ? Icons.language : Icons.translate,
                          color: AppTheme.primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            isSpanish = !isSpanish;
                          });
                          widget.setLocale(isSpanish
                              ? 'es'
                              : 'en'); // Update language locale
                        },
                      ),
                    ),
                    Image.asset(
                      "assets/logo.png",
                      height: isWeb ? 150 : 100,
                    ),
                    const SizedBox(height: 20),

                    // Email TextField
                    SlideTransition(
                      position: _animation,
                      child: TextField(
                        onChanged: (value) => adminEmail = value,
                        style: const TextStyle(
                            fontSize: 16, color: AppTheme.secondaryColor),
                        decoration: InputDecoration(
                          enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.pinkAccent, width: 2)),
                          focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.amber, width: 2)),
                          hintText: isSpanish ? "Correo Electrónico" : "Email",
                          hintStyle:
                              const TextStyle(color: AppTheme.accentColor),
                          prefixIcon: const Icon(Icons.email,
                              color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Password TextField
                    SlideTransition(
                      position: _animation,
                      child: TextField(
                        onChanged: (value) => adminPassword = value,
                        obscureText: true,
                        style: const TextStyle(
                            fontSize: 16, color: AppTheme.secondaryColor),
                        decoration: InputDecoration(
                          enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.pinkAccent, width: 2)),
                          focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.amber, width: 2)),
                          hintText: isSpanish ? "Contraseña" : "Password",
                          hintStyle:
                              const TextStyle(color: AppTheme.accentColor),
                          prefixIcon: const Icon(Icons.admin_panel_settings,
                              color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Login Button
                    ElevatedButton(
                      onPressed: allowAdminToLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 100, vertical: 20),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.pinkAccent,
                      ),
                      child: Text(
                        isSpanish ? "Iniciar sesión" : "Login",
                        style: const TextStyle(
                            color: Colors.white,
                            letterSpacing: 2,
                            fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
