import 'package:flutter/material.dart';

class PasswordInput extends StatelessWidget {
  final Function onSaved;
  final TextEditingController controller;

  const PasswordInput({@required this.onSaved,@required  this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Password'),
      obscureText: true,
      controller: controller,
      validator: (value) {
        if (value.isEmpty || value.length < 5) {
          return 'Password is too short!';
        }
      },
      onSaved: onSaved,
    );
  }
}
