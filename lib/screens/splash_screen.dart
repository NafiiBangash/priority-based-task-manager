import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_manager/screens/sign_in_screen.dart';
import 'package:task_manager/utils/size_config.dart';
import 'package:task_manager/widgets/gradient_background.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _logoSize = 200;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Animate logo and text appearance
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0;
        _logoSize = 150; // Increase logo size smoothly
      });
    });

    //  Wait 3 seconds, then check authentication state
    Timer(const Duration(seconds: 3), () {
      User? user = FirebaseAuth.instance.currentUser;

      //  Navigate based on login status
      Widget nextScreen = (user != null) ? HomeScreen() : const SignInScreen();

      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
            child: child,
          );
        },
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    MySize().init(context);
    return Scaffold(
      body: Stack(
        children: [
          //  Gradient Background
          const GradientBackground(),

          // Splash Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  height: _logoSize,
                  width: _logoSize,
                  child: Image.asset('assets/tm_logo.png'),
                ),

                SizedBox(height: MySize.size40),

                // Animated Text
                AnimatedOpacity(
                  duration: const Duration(seconds: 1),
                  opacity: _opacity,
                  child: Text(
                    'TASK MANAGER',
                    style: GoogleFonts.montserrat(
                      textStyle: TextStyle(
                        color: Colors.white,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                        fontSize: MySize.size24,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: MySize.size20),

                // Loading Indicator
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
