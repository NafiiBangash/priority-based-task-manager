import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_manager/utils/size_config.dart';
import 'package:task_manager/utils/utils.dart';
import 'package:task_manager/widgets/gradient_background.dart';
import 'package:task_manager/widgets/text_field_widget.dart';
import 'sign_up_screen.dart';
import 'home_screen.dart';
import 'package:email_validator/email_validator.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String errorMessage = "";

  void _signIn()async{
    if (!_formKey.currentState!.validate()) {
      return; // ❌ Stop sign-in if validation fails
    }
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ).then((value){
        Utils().showSuccessToast('Sign-in Successful!');
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }).onError((e,s){
        Utils().showErrorToast('Oops! Something went wrong..');
      });
  }

  @override
  Widget build(BuildContext context) {
    MySize().init(context);
    return Scaffold(
      body: Stack(
        children: [
          //  Modern Gradient Background
          const GradientBackground(),

          //  Sign-In Form with Glassmorphism Effect
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Glass effect
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Sign In",
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    //  Email Input
                    TextFormFieldWidget(label: 'Email', controller: _emailController,
                        iconData: Icons.email,
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Email is required";
                        if (!EmailValidator.validate(value)) return "Enter a valid email";
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    //  Password Input
                    TextFormFieldWidget(label: 'Password', controller: _passwordController,
                        iconData: Icons.lock,obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Password is required";
                        if (value.length < 6) return "Password must be at least 6 characters";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 🔥 Animated Sign-In Button
                    ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(horizontal: MySize.size40, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: Text(
                        "Sign In",
                        style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 🔹 "Don't Have an Account?" Text Button
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
                      },
                      child: Text(
                        "Don't have an account? Sign Up",
                        style: GoogleFonts.montserrat(fontSize: 14, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
