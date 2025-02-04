import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oasis_fragrances/admin_files/admin_home_screen.dart';

import '../../utils/const.dart';
import '../../widgets/loading_dialoge.dart';

class AdminRegisterScreen extends StatefulWidget {
  final Function(String) setLocale;
  final String language;

  const AdminRegisterScreen(
      {super.key, required this.setLocale, required this.language});

  @override
  _AdminRegisterScreenState createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen>
    with SingleTickerProviderStateMixin {
  String adminName = "";
  String adminEmail = "";
  String adminPassword = "";
  final _formKey = GlobalKey<FormState>();

  late AnimationController _controller;
  late Animation<Offset> _animation;

  bool get isSpanish => widget.language == "spanish";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.05, 0),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticIn),
    );
  }

  void _triggerVibration() {
    HapticFeedback.vibrate();
    _controller.forward().then((value) => _controller.reverse());
  }

  Future<void> registerAdmin() async {
    if (!_formKey.currentState!.validate()) {
      _triggerVibration();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialoge(
        message: isSpanish ? "Registrando..." : "Registering",
      ),
    );

    try {
      final authResult =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      final User? newAdmin = authResult.user;

      if (newAdmin != null) {
        await FirebaseFirestore.instance
            .collection("admins")
            .doc(newAdmin.uid)
            .set({
          "adminName": adminName,
          "adminEmail": adminEmail,
          "uid": newAdmin.uid,
          "createdAt": DateTime.now(),
        });

        Navigator.pop(context); // Close the loading dialog
        _showSnackBar(
            isSpanish ? "¡Registro exitoso!" : "Registration successful!",
            Colors.green);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminHomeScreen(
              setLocale: widget.setLocale,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close the loading dialog

      String errorMessage;
      if (e.code == 'email-already-in-use') {
        errorMessage = isSpanish
            ? "Este correo ya está en uso."
            : "This email is already in use.";
      } else if (e.code == 'invalid-email') {
        errorMessage =
            isSpanish ? "Formato de correo inválido." : "Invalid email format.";
      } else if (e.code == 'weak-password') {
        errorMessage = isSpanish
            ? "La contraseña debe tener al menos 6 caracteres."
            : "Password should be at least 6 characters.";
      } else {
        errorMessage = isSpanish
            ? "Ocurrió un error inesperado: ${e.message}"
            : "An unexpected error occurred: ${e.message}";
      }

      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      Navigator.pop(context); // Close the loading dialog
      _showSnackBar(
          isSpanish
              ? "Ocurrió un error. Inténtalo de nuevo."
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

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWeb = constraints.maxWidth > 600;
          return Center(
            child: Container(
              width: isWeb ? screenWidth * 0.4 : screenWidth * 0.9,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/logo.png",
                      height: isWeb ? 150 : 100,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      hint: isSpanish ? "Nombre" : "Name",
                      icon: Icons.person,
                      onChanged: (value) => adminName = value,
                      validator: (value) => value == null || value.isEmpty
                          ? (isSpanish
                              ? "El nombre no puede estar vacío."
                              : "Name cannot be empty.")
                          : null,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      hint: isSpanish ? "Correo electrónico" : "Email",
                      icon: Icons.email,
                      onChanged: (value) => adminEmail = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return isSpanish
                              ? "El correo no puede estar vacío."
                              : "Email cannot be empty.";
                        }
                        if (!RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-z]+$')
                                .hasMatch(value) ||
                            !value.endsWith('.com')) {
                          return isSpanish
                              ? "Ingrese un correo válido que termine en .com."
                              : "Enter a valid email ending with .com.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      hint: isSpanish ? "Contraseña" : "Password",
                      icon: Icons.lock,
                      obscureText: true,
                      onChanged: (value) => adminPassword = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return isSpanish
                              ? "La contraseña no puede estar vacía."
                              : "Password cannot be empty.";
                        }
                        if (value.length < 6) {
                          return isSpanish
                              ? "La contraseña debe tener al menos 6 caracteres."
                              : "Password must be at least 6 characters.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: registerAdmin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 100, vertical: 20),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.pinkAccent,
                      ),
                      child: Text(
                        isSpanish ? "Registrarse" : "Register",
                        style: const TextStyle(
                          color: Colors.white,
                          letterSpacing: 2,
                          fontSize: 16,
                        ),
                      ),
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

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required void Function(String) onChanged,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return SlideTransition(
      position: _animation,
      child: TextFormField(
        onChanged: onChanged,
        obscureText: obscureText,
        style: TextStyle(fontSize: 16, color: AppTheme.secondaryColor),
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.pinkAccent, width: 2)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.amber, width: 2)),
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.accentColor),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        ),
        validator: validator,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
