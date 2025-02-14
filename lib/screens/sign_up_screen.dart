import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_manager/utils/utils.dart';
import 'package:task_manager/widgets/gradient_background.dart';
import 'package:task_manager/widgets/text_field_widget.dart';
import '../utils/size_config.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String errorMessage = "";
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _signUp() async{
    if (!_formKey.currentState!.validate()) {
      return; // ❌ Stop sign-up if validation fails
    }
    await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ).then((value){
        Utils().showSuccessToast("Successfully Created");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignInScreen()));
    }).onError((error,stackTrace){
      Utils().showErrorToast("Failed To create");
    });
  }

  @override
  Widget build(BuildContext context) {
    MySize().init(context);
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          const GradientBackground(),

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
                      "Sign Up",
                      style: GoogleFonts.montserrat(
                        fontSize: MySize.size28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    //  Name Input
                    TextFormFieldWidget(label: 'Full Name', controller: _nameController, iconData: Icons.person,
                    validator: (value){
                      if (value == null || value.isEmpty) {
                        return "Name is required";
                      }
                      return null;
                    },),
                    const SizedBox(height: 15),
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
                    //  Animated Sign-Up Button
                    ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: Text(
                        "Sign Up",
                        style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Already Have an Account? Sign In
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInScreen())),
                      child: Text(
                        'Already have an account? Sign In',
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(color: Colors.white70),
                        ),
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
