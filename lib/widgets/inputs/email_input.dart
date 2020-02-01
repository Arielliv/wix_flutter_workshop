import 'package:flutter/material.dart';

class EmailInput extends StatelessWidget {
  final Function onSaved;

  const EmailInput({@required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        decoration: InputDecoration(labelText: 'E-Mail'),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value.isEmpty || !value.contains('@')) {
            return 'Invalid email!';
          }
        },
        onSaved: (value) => onSaved(value));
  }
}
