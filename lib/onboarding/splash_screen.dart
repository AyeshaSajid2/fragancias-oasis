import 'package:flutter/material.dart';
import 'package:oasis_fragrances/screens/home_screen.dart'; // Import your home screen

class SplashScreen extends StatefulWidget {
  final Function(String) setLocale; // Declare the setLocale parameter

  const SplashScreen({super.key, required this.setLocale});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool showRipple = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showRipple = false;
      });

      Future.delayed(const Duration(seconds: 2), () {
        // Pass setLocale when navigating to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => HomeScreen(
                  setLocale: widget.setLocale)), // Pass setLocale here
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedOpacity(
                  opacity: showRipple ? 0.0 : 1.0,
                  duration: const Duration(seconds: 2),
                  child: Container(
                    width: screenWidth * 0.3,
                    height: screenWidth * 0.3,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/logo.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                AnimatedOpacity(
                  opacity: showRipple ? 1.0 : 0.0,
                  duration: const Duration(seconds: 1),
                  child: AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    width: showRipple ? screenWidth * 0.6 : 0,
                    height: showRipple ? screenHeight * 0.1 : 0,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(215, 210, 210, 1.0),
                      borderRadius: BorderRadius.all(Radius.elliptical(
                        screenWidth * 0.6,
                        screenHeight * 0.1,
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
