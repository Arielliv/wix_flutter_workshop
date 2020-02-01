import 'package:flutter/material.dart';
import 'package:wix_flutter_workshop/screens/Items_overview_screen.dart';
import 'package:provider/provider.dart';
import 'package:wix_flutter_workshop/providers/auth.dart';
import 'package:wix_flutter_workshop/screens/auth_screen.dart';
import 'package:wix_flutter_workshop/screens/splash_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Auth(),
        ),
      ],
      child: Consumer<Auth>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'Wix Flutter Workshop',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            accentColor: Colors.orange,
          ),
          home: auth.isAuth
              ? ItemsOverviewScreen()
              : FutureBuilder(
                  future: auth.tryAutoLogin(),
                  builder: (context, authResultSnapshot) =>
                      authResultSnapshot.connectionState ==
                              ConnectionState.waiting
                          ? SplashScreen()
                          : AuthScreen(),
                ),
        ),
      ),
    );
  }
}
