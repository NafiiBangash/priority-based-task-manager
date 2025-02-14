import 'package:flutter/material.dart';

class TextFormFieldWidget extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? textInputType;
  final IconData iconData;
  final bool obscureText;
  final String? Function(String?)? validator;

   const TextFormFieldWidget({super.key, required this.label,
     required this.controller,this.textInputType,
     required this.iconData,this.obscureText = false, this.validator});

  @override
  State<TextFormFieldWidget> createState() => _TextFormFieldWidgetState();
}

class _TextFormFieldWidgetState extends State<TextFormFieldWidget> {
  late bool _isObscure;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _isObscure = widget.obscureText;
  }
  @override
  Widget build(BuildContext context) {
    return  TextFormField(
      controller: widget.controller,
      cursorColor: Colors.white,
      obscureText: _isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.iconData, color: Colors.white70),
        suffixIcon:  widget.obscureText?IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ):const SizedBox.shrink(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white70),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: widget.validator,
    );
  }
}
