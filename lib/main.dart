import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './screens/Items_overview_screen.dart';
import './providers/auth.dart';
import './screens/auth_screen.dart';
import './screens/splash_screen.dart';
import './providers/items.dart';

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
        ChangeNotifierProxyProvider<Auth, Items>(
          builder: (ctx, auth, prevpItems) => Items(
            auth.token,
            auth.userId,
            prevpItems == null ? [] : prevpItems.items,
          ),
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
