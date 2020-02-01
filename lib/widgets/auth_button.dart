import 'package:flutter/material.dart';
import 'package:wix_flutter_workshop/screens/auth_screen.dart';

class AuthButton extends StatelessWidget {
  final bool isLoading;
  final AuthMode authMode;
  final Function onSubmit;
  
  AuthButton(
      {@required this.isLoading,
      @required this.authMode,
      @required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return CircularProgressIndicator();
    else
      return RaisedButton(
        child: Text(authMode == AuthMode.Login ? 'LOGIN' : 'SIGN UP'),
        onPressed: onSubmit,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
        color: Theme.of(context).primaryColor,
        textColor: Theme.of(context).primaryTextTheme.button.color,
      );
  }
}
