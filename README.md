pre

# *flutter workshop*

## Prerequisites

- follow the instraction - https://flutter.dev/docs/get-started/install/macos (you can skip iOS setup).
- I recommand to use VSCode - https://code.visualstudio.com/
    - Download flutter extention:
     -in VSCode go to view -> Extainsions -> search for flutter -> install it
        
        or

        <kbd>shift</kbd> <kbd>command</kbd> <kbd>x</kbd> -> search for flutter and install it.
also install mateirial Icon theme - <kbd>shift</kbd> <kbd>command</kbd> <kbd>x</kbd> - search for flutter and install it.
- For those who forgot - Install android studio(so you can use their simulator) - https://developer.android.com/studio/?gclid=EAIaIQobChMIpo7-tIH75QIVGODtCh127QL1EAAYASAAEgLqi_D_BwE

by the end you should be able to run flutter doctor on this project and succeed.

flutter create --androidx

## cheat list VSCode

<kbd>option</kbd> <kbd>shift</kbd> <kbd>F</kbd> -> format your code

<kbd>control</kbd> <kbd>shift</kbd> <kbd>R</kbd> -> helps you when you need to create/change widgets 

# Let's build a Image posting app

run `flutter create --androidx [pick a name for your app]`

after it finish, try to run your new app,in vscode you can click on `debug` -> `start without debuging`
(you can start it from the terminal by runing the command `flutter run`).

## first step - Login And register page

- first step will be to edit `pubspec.yaml` file. 
this file is like package.json in node. 
Every `pub package` needs some metadata so it can specify its `dependencies`. you add some pub packges so we coul use them later. 

add this piece of code to `pubspec.yaml` file, under this lines :
```
dependencies:
  flutter:
    sdk: flutter
```

### note :exclamation: 
The indention is realy importent here!
keep all the packes in same space line as `flutter` packege is.


```javascript
provider: ^3.1.0
intl: ^0.16.0
http: ^0.12.0+2
shared_preferences: ^0.5.4+3
image_picker: ^0.6.2+1
path_provider: ^1.4.4
firebase_storage: ^3.1.0
```

- lets create some folders 
our main workplace folder will be `lib`.
we can create all `dart` file under it , but we will prefer to make some sub folders, to make it easier and cleaner.

lets make `screens`, `widgets`, `models` and `providers`.

now under `models` folder we need to create `http_exception.dart` file and copy this inside :

```
class HttpException implements Exception{
  final String message;
  
  HttpException(this.message);

  @override
  String toString() {
    return message;
  }

}
```

also we need to create under `providers` folder , we need to create `auth.dart` which will have out login, signin and logut logic: 

```
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/http_exception.dart';

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiryDate;
  String _userId;
  Timer _authTimer;

  bool get isAuth {
    return token != null;
  }

  String get token {
    if (_expiryDate != null &&
        _expiryDate.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    } else {
      return null;
    }
  }

  String get userId {
    return _userId;
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    final url =
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyCngoLTNTKO-D8eX3D_-9lrTNNzbPr5Gvk';
    try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            'email': email,
            'password': password,
            'returnSecureToken': true,
          },
        ),
      );
      final responseData = json.decode(response.body);
      if (responseData['error'] != null) {
        throw HttpException(responseData['error']['message']);
      }
      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: int.parse(
            responseData['expiresIn'],
          ),
        ),
      );

      _autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode(
        {
          'token': _token,
          'userId': _userId,
          'expiryDate': _expiryDate.toIso8601String()
        },
      );
      prefs.setString('userData', userData);
    } catch (error) {
      throw error;
    }
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    } else {
      final extractedUserData =
          json.decode(prefs.getString('userData')) as Map<String, Object>;
      final expiryDate = DateTime.parse(extractedUserData['expiryDate']);
      if (expiryDate.isBefore(DateTime.now())) {
        return false;
      } else {
        _token = extractedUserData['token'];
        _userId = extractedUserData['userId'];
        _expiryDate = expiryDate;
        notifyListeners();
        _autoLogout();
        return true;
      }
    }
  }

  Future<void> logout() async{
    _token = null;
    _userId = null;
    _expiryDate = null;
    if (_authTimer != null) {
      _authTimer.cancel();
      _authTimer = null;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');
    prefs.clear();
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer.cancel();
    } else {
      final timeToExpiry = _expiryDate.difference(DateTime.now()).inSeconds;
      _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
    }
  }
}
```

and now we will change our `main.dart` file, this file controls our app `theme` , app `font` also page lending, and routs.its basiclly runs our entire app.

until now we had deafult config from what `flutter create` made for us, lets change it.
we will change `MyApp` class
we can delete `MyHomePage` and `_MyHomePageState`

```
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
```

please make sure you have both of this lines in top of the page:

```
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
```


now we have some missing widgets and screens -  lets create them.

- create under `screens` folder `Items_overview_screen.dart`
    - we will create our first `StatefulWidget` .
    if you are using vsCode, start writing st and it will suggest you whether to create statefull widget or stateless widget, pick statefull.
    name the class `ItemsOverviewScreen` .
    make sure to import `material.dart`, we will need to use it widgets.

    instade of returning `container` widget , we will return `Scaffold`. (This widget provides APIs for showing drawers, snack bars, and bottom sheets)
    for now we will returen scaffold with `appBar` and `body`.
    - the app bar we will be `AppBar` widget with title.
    the title will be using `Text` widget.

    ```
    appBar: AppBar(
        title: Text('Flutter Workshop'),
      ),
    ```

    - the body will be  `CircularProgressIndicator`, ui widget which we can use for loader for now.
(A material design circular progress indicator, which spins to indicate that the application is busy). we also will want our `body` to be center , therfore we will return the `CircularProgressIndicator` inside `Center` widget
    ```
    body: Center(
        child: CircularProgressIndicator(),
      ),
    ```

it suppose to look like this :

    ```
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Workshop'),
      ),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
    ```

now in our `main.dart` file we can use our freash widget. we just need to import it at the top of the page - 
```
import './screens/Items_overview_screen.dart';
``` 

now lets create the `splash_screen`
- in `screens` folder we need to create `splash_screen.dart`
- this widget will be stateless widget.
- again we will return `Scaffold` widget which will contain body property with `Center` widget and `Text` widget inside of it , with ''Loading...'' as text.
- afterwords add 
    ```
    import './screens/splash_screen.dart';
    ```
    to `main.dart` file

    <details>
    <summary>splash_screen</summary>

    ```
    import 'package:flutter/material.dart';

    class SplashScreen extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return Scaffold(
        body: Center(
            child: Text('Loading...'),
        ),
        );
    }
    }
    ```
    </details>

now lets create the `auth_screen`
- it will be `StatelessWidget`
- dont forget to import `'package:flutter/material.dart'`
- it will return `Scaffold`. As you can see , each screen return `Scaffold` widget.
- we will use `Stack` widget (This widget is useful if you want to overlap several children in a simple way, for example having some text and an image, overlaid with a gradient and a button attached to the bottom). we will make the first widget `Stack` a continer , and the second  `SingleChildScrollView`
- `SingleChildScrollView` is used when we want to enable scrolling over a widget (A box in which a single widget can be scrolled)
- inside `SingleChildScrollView` we will use `Continer` as child , and this time we will have to give it `height` and `width` properties beacuse its inside a `Stack`.
- we don't want to give it a fixed size like hight :50, width: 50, it maybe good for our spesific simulator , but we got tons of diffrent phones sizes. 
- we will use `context` to get th simulator size. inside `Build` function we will add this code : 
    ```
    final deviceSize = MediaQuery.of(context).size;
    ```  
- now we can use `deviceSize` 
    ```
    height: deviceSize.height,
    width: deviceSize.width,
    ```
- inside child propery we will add `Column` widget (A widget that displays its children in a vertical array).
- we will want to center our login/sing in widget, therefoe we will add
    ```
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    ```
- now lets use `Flexible` widget which will be evantually title for our auth screen. it will have `Container` as a child.(Flexible is a widget that controls how a child of a Row, Column, or Flex flexes.Using a Flexible widget gives a child of a Row, Column, or Flex the flexibility to expand to fill the available space)

- lets add some ui stuff to the `Container`  
    ``` 
    margin: EdgeInsets.only(bottom: 20.0),
    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 94.0),
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white70,
        boxShadow: [
            BoxShadow(
            blurRadius: 8,
            color: Colors.black26,
            offset: Offset(0, 2),
            )
        ],
    ),
    ```
- the child widget will be `Text`, with 'Workshop' as text,
- also lets add the style property , with `TextStyle` widget inside.
    - we will use color from our `theme`, we will get it again from `context`, like this: 
    ```
    color: Theme.of(context).accentTextTheme.title.color
    ```
    we also want to add font style -
    ```
    fontSize: 42,
    fontFamily: 'Anton',
    fontWeight: FontWeight.normal,
    ```

- now back to `Column -> children array` , lets add another `Flexible`. it will have two properties:
    ```
    flex: deviceSize.width > 600 ? 2 : 1,
    child: AuthCard(),
    ```

<details>
    <summary>auth_screen</summary>

    
    import 'package:flutter/material.dart';

    enum AuthMode { Signup, Login }

    class AuthScreen extends StatelessWidget {
    static const routeName = '/auth';

    @override
    Widget build(BuildContext context) {
        final deviceSize = MediaQuery.of(context).size;
    
        return Scaffold(
        body: Stack(
            children: <Widget>[
            Container(
                decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.9),
                ),
            ),
            Container(
                child: Container(
                height: deviceSize.height,
                width: deviceSize.width,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                    Flexible(
                        child: Container(
                        margin: EdgeInsets.only(bottom: 20.0),
                        padding:
                            EdgeInsets.symmetric(vertical: 8.0, horizontal: 94.0),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white70,
                            boxShadow: [
                            BoxShadow(
                                blurRadius: 8,
                                color: Colors.black26,
                                offset: Offset(0, 2),
                            )
                            ],
                        ),
                        child: Text(
                            'Workshop',
                            style: TextStyle(
                            color: Theme.of(context).accentTextTheme.title.color,
                            fontSize: 42,
                            fontFamily: 'Anton',
                            fontWeight: FontWeight.normal,
                            ),
                        ),
                        ),
                    ),
                    Flexible(
                        flex: deviceSize.width > 600 ? 2 : 1,
                        child: AuthCard(),
                    ),
                    ],
                ),
                ),
            ),
            ],
        ),
        );
    }
    }
</details>

- now we can add `auth_screen` import in `main.dart` file
```
import './screens/auth_screen.dart';
```

now we need to create `AuthCard` widget
- in `widgets` folder we will create `auth_card.dart`, `auth_button.dart` and `inputs` folder

## auth button
- lets create `StatelessWidget` named as `AuthButton`
- this time it will pass parameters to the widget `isLoading`,`authMode` and `onSubmit` (just like props in react)
- we will create properties in `AuthButton` class , and they will be `final` (its a `StatelessWidget`, once it renders it wont change under any circumstances).
    example :
    ```
    class AuthButton extends StatelessWidget {
    final bool isLoading;
    ```
- `authMode` will be of type `AuthMode`, and `onSubmit` will be type of `Function`
- we need create Constructor with named parameters
```
AuthButton(
    {@required this.isLoading,
    @required this.authMode,
    @required this.onSubmit}
);
```

it can also be written like this 
```
AuthButton(
        @required this.isLoading,
        @required this.authMode,
        @required this.onSubmit);
```
but then the order of the parameters will be importent, and you wont get the benefits of named parameters.

```

AuthButton(false, authMode, () =>{}))

VS

AuthButton(isLoading: false, authMode: authMode, onSubmit: () =>{}))
```
- inside build method we will return `RaisedButton` (A material design "raised button").

- in child propety will have `Text`, it will have to modes `login` and `sign in` - 
```
Text(authMode == AuthMode.Login ? 'LOGIN' : 'SIGN UP'),
```
- `onPress` will have `onSubmit` function we got
- time for styling 
```
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
    ),
    padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
    color: Theme.of(context).primaryColor,
    textColor: Theme.of(context)  .primaryTextTheme.button.color,
```
- we also want to handle loading stage , so we need to wrapp RaisedButton with `if else` segment. if `isLoading` true then return `CircularProgressIndicator` else return `RaisedButton`

<details>
<summary>auth button</summary>

    import 'package:flutter/material.dart';
    import '../screens/auth_screen.dart';

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
</details>

## inputs
### email input
- in `inputs` folder , lets create `email_input.dart` file
- it will be `StatelessWidget` which gets `onSaved` function
- we will return `TextFormField` widget (This is a convenience widget that wraps a TextField widget in a FormField).
- In decoretion property we will use `InputDecoration` with`labelText` of 'E-Mail'
- keyboardType will be `TextInputType.emailAddress`
- we will also want to validate it - in `validator` property we will have this code : 
    ```
    validator: (value) {
                if (value.isEmpty || !value.contains('@')) {
                    return 'Invalid email!';
                }
                },
    ```
- onSaved will pass the value
    ```
    onSaved: (value) => onSaved(value));
    ```

<details>
<summary>email_input</summary>

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

</details>

### password input
- in `inputs` folder , lets create `password_input.dart` file
- it will be really similar to email input
- it will be `StatelessWidget` which gets `onSaved` function and `controller` type of `TextEditingController`
- we will return `TextFormField` widget.
- In decoretion property we will use `InputDecoration` with`labelText` of 'Password'
- it will have controller which will handle the updating 
    ```
    obscureText: true,
    controller: controller,
    ```
- we will also want to validate it - in `validator` property we will have this code : 
    ```
    validator: (value) {
        if (value.isEmpty || value.length < 5) {
          return 'Password is too short!';
        }
      },
    ```
- onSaved will trigger the `onSave` function
    ```
    onSaved
    ```

<details>
<summary>password_input.dart</summary>

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

</details>

and now finnely we can create the `auth_card.dart` file

### auth_card

- it will be `StatefulWidget`
- add under `class AuthCard` 
    ```
    const AuthCard({
    Key key,
  }) : super(key: key);
    ```
- add `with SingleTickerProviderStateMixin` to `_AuthCardState` so we could to enable useage of `animationController` in `state`
- create properties od class : 
    ```
    final GlobalKey<FormState> _formKey = GlobalKey();
  AuthMode _authMode = AuthMode.Login;

  Map<String, String> _authData = {
    'email': '',
    'password': '',
  };

  var _isLoading = false;
  final _passwordController = TextEditingController();
  AnimationController _controller;
  Animation<Offset> _slideAnimation;
  Animation<double> _opacityAnimation;
  ```
- copy this snippet of code , look for the right place where to add `authButton`, `emailInput` and `passwordInput`, you will have to pass the right parameters
- for the `onSave` function you will have to pass value and the right key , example : 
```
(value) => _onSaveField('password', value)
```
- make sure to import 
    ```
    import 'dart:io';

    import 'package:flutter/material.dart';
    import 'package:provider/provider.dart';
    ```

snippet :

```
    @override
    void initState() {
        super.initState();
        _controller = AnimationController(
        vsync: this,
        duration: Duration(
            milliseconds: 300,
        ),
        );
        _slideAnimation = Tween<Offset>(
        begin: Offset(0, -1.5),
        end: Offset(0, 0),
        ).animate(
        CurvedAnimation(
            parent: _controller,
            curve: Curves.easeIn,
        ),
        );

        _opacityAnimation = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: Curves.easeIn,
        ),
        );
    }

    @override
    void dispose() {
        super.dispose();
        _controller.dispose();
    }

    void _showErrorDialog(String message) {
        showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: Text(
            'An error occured',
            ),
            content: Text(message),
            actions: <Widget>[
            FlatButton(
                child: Text('Okay'),
                onPressed: () {
                Navigator.of(ctx).pop();
                },
            )
            ],
        ),
        );
    }

    Future<void> _submit() async {
        if (!_formKey.currentState.validate()) {
        // Invalid!
        return;
        }
        _formKey.currentState.save();
        setState(() {
        _isLoading = true;
        });
        try {
        if (_authMode == AuthMode.Login) {
            // Log user in
            await Provider.of<Auth>(context, listen: false).login(
            _authData['email'],
            _authData['password'],
            );
        } else {
            // Sign user up
            await Provider.of<Auth>(context, listen: false).signup(
            _authData['email'],
            _authData['password'],
            );
        }
        } on HttpException catch (error) {
        var errorMessage = 'Authenticate failed';
        if (error.toString().contains('EMAIL_EXISTS')) {
            errorMessage = 'This email address already in use';
        } else if (error.toString().contains('INVALID_EMAIL')) {
            errorMessage = 'This is not a valid email address';
        } else if (error.toString().contains('WEAK_PASSWORD')) {
            errorMessage = 'This password is too weak';
        } else if (error.toString().contains('EMAIL_NOT_FOUND')) {
            errorMessage = 'Could not find a user with that email';
        } else if (error.toString().contains('INVALID_PASSWORD')) {
            errorMessage = 'This is not a valid password address';
        }
        _showErrorDialog(errorMessage);
        } catch (error) {
        const errorMessage = 'Could not authenticate you. Please try again later';
        _showErrorDialog(errorMessage);
        }
        setState(() {
        _isLoading = false;
        });
    }

    void _switchAuthMode() {
        if (_authMode == AuthMode.Login) {
        setState(() {
            _authMode = AuthMode.Signup;
        });
        _controller.forward();
        } else {
        setState(() {
            _authMode = AuthMode.Login;
        });
        _controller.reverse();
        }
    }

    void _onSaveField(String key, String value) {
        _authData[key] = value;
    }

    @override
    Widget build(BuildContext context) {
        final deviceSize = MediaQuery.of(context).size;
        return Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 8.0,
        child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeIn,
            height: _authMode == AuthMode.Signup ? 320 : 260,
            constraints:
                BoxConstraints(minHeight: _authMode == AuthMode.Signup ? 320 : 260),
            width: deviceSize.width * 0.75,
            padding: EdgeInsets.all(16.0),
            child: Form(
            key: _formKey,
            child: SingleChildScrollView(
                child: Column(
                children: <Widget>[
                    ##### add EmailInput ######,
                    ##### add PasswordInput ######,
                    AnimatedContainer(
                    constraints: BoxConstraints(
                        minHeight: _authMode == AuthMode.Signup ? 60 : 0,
                        maxHeight: _authMode == AuthMode.Signup ? 120 : 0,
                    ),
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                    child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                        opacity: _opacityAnimation,
                        child: TextFormField(
                            enabled: _authMode == AuthMode.Signup,
                            decoration:
                                InputDecoration(labelText: 'Confirm Password'),
                            obscureText: true,
                            validator: _authMode == AuthMode.Signup
                                ? (value) {
                                    if (value != _passwordController.text) {
                                    return 'Passwords do not match!';
                                    }
                                }
                                : null,
                        ),
                        ),
                    ),
                    ),
                    SizedBox(
                    height: 20,
                    ),
                    ##### add AuthButton ######,
                    FlatButton(
                    child: Text(
                        '${_authMode == AuthMode.Login ? 'SIGNUP' : 'LOGIN'} INSTEAD'),
                    onPressed: _switchAuthMode,
                    padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textColor: Theme.of(context).primaryColor,
                    ),
                ],
                ),
            ),
            ),
        ),
        );
    }
  ```

<details>
    <summary>auth_card.dart</summary>

    import 'dart:io';
    import 'package:flutter/material.dart';
    import 'package:provider/provider.dart';
    import 'package:wix_flutter_workshop/providers/auth.dart';
    import 'package:wix_flutter_workshop/screens/auth_screen.dart';
    import 'package:wix_flutter_workshop/widgets/auth_button.dart';
    import 'package:wix_flutter_workshop/widgets/inputs/email_input.dart';
    import 'package:wix_flutter_workshop/widgets/inputs/password_input.dart';
    import '../models/http_exception.dart';

    class AuthCard extends StatefulWidget {
    const AuthCard({
        Key key,
    }) : super(key: key);

    @override
    _AuthCardState createState() => _AuthCardState();
    }

    class _AuthCardState extends State<AuthCard>
        with SingleTickerProviderStateMixin {
    final GlobalKey<FormState> _formKey = GlobalKey();
    AuthMode _authMode = AuthMode.Login;

    Map<String, String> _authData = {
        'email': '',
        'password': '',
    };

    var _isLoading = false;
    final _passwordController = TextEditingController();
    AnimationController _controller;
    Animation<Offset> _slideAnimation;
    Animation<double> _opacityAnimation;

    @override
    void initState() {
        super.initState();
        _controller = AnimationController(
        vsync: this,
        duration: Duration(
            milliseconds: 300,
        ),
        );
        _slideAnimation = Tween<Offset>(
        begin: Offset(0, -1.5),
        end: Offset(0, 0),
        ).animate(
        CurvedAnimation(
            parent: _controller,
            curve: Curves.easeIn,
        ),
        );

        _opacityAnimation = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: Curves.easeIn,
        ),
        );
    }

    @override
    void dispose() {
        super.dispose();
        _controller.dispose();
    }

    void _showErrorDialog(String message) {
        showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: Text(
            'An error occured',
            ),
            content: Text(message),
            actions: <Widget>[
            FlatButton(
                child: Text('Okay'),
                onPressed: () {
                Navigator.of(ctx).pop();
                },
            )
            ],
        ),
        );
    }

    Future<void> _submit() async {
        if (!_formKey.currentState.validate()) {
        // Invalid!
        return;
        }
        _formKey.currentState.save();
        setState(() {
        _isLoading = true;
        });
        try {
        if (_authMode == AuthMode.Login) {
            // Log user in
            await Provider.of<Auth>(context, listen: false).login(
            _authData['email'],
            _authData['password'],
            );
        } else {
            // Sign user up
            await Provider.of<Auth>(context, listen: false).signup(
            _authData['email'],
            _authData['password'],
            );
        }
        } on HttpException catch (error) {
        var errorMessage = 'Authenticate failed';
        if (error.toString().contains('EMAIL_EXISTS')) {
            errorMessage = 'This email address already in use';
        } else if (error.toString().contains('INVALID_EMAIL')) {
            errorMessage = 'This is not a valid email address';
        } else if (error.toString().contains('WEAK_PASSWORD')) {
            errorMessage = 'This password is too weak';
        } else if (error.toString().contains('EMAIL_NOT_FOUND')) {
            errorMessage = 'Could not find a user with that email';
        } else if (error.toString().contains('INVALID_PASSWORD')) {
            errorMessage = 'This is not a valid password address';
        }
        _showErrorDialog(errorMessage);
        } catch (error) {
        const errorMessage = 'Could not authenticate you. Please try again later';
        _showErrorDialog(errorMessage);
        }
        setState(() {
        _isLoading = false;
        });
    }

    void _switchAuthMode() {
        if (_authMode == AuthMode.Login) {
        setState(() {
            _authMode = AuthMode.Signup;
        });
        _controller.forward();
        } else {
        setState(() {
            _authMode = AuthMode.Login;
        });
        _controller.reverse();
        }
    }

    void _onSaveField(String key, String value) {
        _authData[key] = value;
    }

    @override
    Widget build(BuildContext context) {
        final deviceSize = MediaQuery.of(context).size;
        return Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 8.0,
        child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeIn,
            height: _authMode == AuthMode.Signup ? 320 : 260,
            constraints:
                BoxConstraints(minHeight: _authMode == AuthMode.Signup ? 320 : 260),
            width: deviceSize.width * 0.75,
            padding: EdgeInsets.all(16.0),
            child: Form(
            key: _formKey,
            child: SingleChildScrollView(
                child: Column(
                children: <Widget>[
                    EmailInput(
                    onSaved: (value) => _onSaveField('email', value),
                    ),
                    PasswordInput(
                        onSaved: (value) => _onSaveField('password', value),
                        controller: _passwordController),
                    AnimatedContainer(
                    constraints: BoxConstraints(
                        minHeight: _authMode == AuthMode.Signup ? 60 : 0,
                        maxHeight: _authMode == AuthMode.Signup ? 120 : 0,
                    ),
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                    child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                        opacity: _opacityAnimation,
                        child: TextFormField(
                            enabled: _authMode == AuthMode.Signup,
                            decoration:
                                InputDecoration(labelText: 'Confirm Password'),
                            obscureText: true,
                            validator: _authMode == AuthMode.Signup
                                ? (value) {
                                    if (value != _passwordController.text) {
                                    return 'Passwords do not match!';
                                    }
                                }
                                : null,
                        ),
                        ),
                    ),
                    ),
                    SizedBox(
                    height: 20,
                    ),
                    AuthButton(
                    isLoading: _isLoading,
                    authMode: _authMode,
                    onSubmit: _submit,
                    ),
                    FlatButton(
                    child: Text(
                        '${_authMode == AuthMode.Login ? 'SIGNUP' : 'LOGIN'} INSTEAD'),
                    onPressed: _switchAuthMode,
                    padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textColor: Theme.of(context).primaryColor,
                    ),
                ],
                ),
            ),
            ),
        ),
        );
    }
    }

</details>
- make sure to import `AuthCard` in `auth_screen`.

now you have everything to login or sign in! 

## home screen

lets start creating our home screen :raised_hands:

1. we need to create 2 new providers : `item` and `items`
2. we need to refactor our `items_overview_screen`
3. we need to create new widget `items_grid`

- under providers directory , cereate `items.dart` and `item.dart` 

- `item` provider will represent our item whom will be save in our server  
it will be `class` that uses `ChangeNotifier` mixin 
    in dart you do it with `with` keyword - 
    
    ```
    class Item with ChangeNotifier
    ```

    it will have those properties:  
    ```
    final String id;
    final String title;
    final String description;
    final double price;
    final File image;
    bool isFavorite;
    ```
    
    make sure to import `foundation.dart` and import `material.dart` from flutter

    ```
    import 'package:flutter/foundation.dart';
    import 'package:flutter/material.dart';
    import 'dart:io';
    ```

    - we will need to create a constractor function
    
    ```
    Item({
        @required this.id,
        @required this.title,
        @required this.description,
        @required this.price,
        this.imagePath,
        this.isFavorite = false,
    });
  ```

<details>
    <summary>item.dart</summary>

    import 'package:flutter/foundation.dart';
    import 'package:flutter/material.dart';

    class Item with ChangeNotifier {
    final String id;
    final String title;
    final String description;
    final double price;
    final File image;
    bool isFavorite;

    Item({
        @required this.id,
        @required this.title,
        @required this.description,
        @required this.price,
        this.image,
        this.isFavorite = false,
    });
    }

</details>

- `items` provider will hold all of our `crud` logic against the server
- we will use `auth` and `user` that we got when we loged in , so we will have permissions over the items
- copy the code from here :arrow_down:

<details>
    <summary>items.dart</summary>

    import 'dart:convert';
    import 'package:flutter/widgets.dart';
    import 'package:http/http.dart' as http;
    import '../providers/item.dart';

    class Items with ChangeNotifier {
    final String baseUrl = 'https://flutter-workshop-eef86.firebaseio.com';
    List<Item> _items = [];

    final String authToken;
    final String userId;

    Items(this.authToken, this.userId, this._items);

    List<Item> get items {
        return [..._items];
    }

    Item findById(String id) {
        return _items.firstWhere((item) => item.id == id);
    }

    Future<void> fetchAndSetItems([bool filterByUser = false]) async {
        final filterUrl =
            filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
        var url = '$baseUrl/items.json?auth=$authToken&$filterUrl';
        print(authToken);
        try {
        final response = await http.get(url);
        final extractedData = json.decode(response.body) as Map<String, dynamic>;
        if (extractedData == null) {
            return;
        } else {
            final List<Item> loadedItems = [];
            extractedData.forEach((itemId, itemData) {
            loadedItems.add(Item(
                id: itemId,
                title: itemData['title'],
                description: itemData['description'],
                price: itemData['price'],
                isFavorite: false,
                image: itemData['image'],
            ));
            });
            _items = loadedItems;

            notifyListeners();
        }
        } catch (error) {
        throw error;
        }
    }
    }

</details>

- please add this lines of code to `main.dart` file inside `providers` array
    
    ```
    ChangeNotifierProxyProvider<Auth, Items>(
            builder: (ctx, auth, prevpItems) => Items(
                auth.token,
                auth.userId,
                prevpItems == null ? [] : prevpItems.items,
            ),
            ),
    ```
    - and import import `items.dart`

- Lets refactor items_overview_screen :muscle:

    until now it was just a widget that render loader,now we will make it show our items

- becasue we now going to work against the server - we will need to handle `Future` and async code , therefoe lets handle the `init` and `load` stage
    
    - create `_isInit` and `_isLoading` vars in `_ProductsOverviewScreenState` class , both should be in initial as false
    - add `didChangeDependencies` (Called when a dependency of this State object changes)
    
        this will handle update of screen when we will get the data back from the server
     
    - we will call `fetchAndSetItems` there to get the products from the server and when it will finish , we will update the state 

    ```
    var _isInit = false;
    var _isLoading = false;

    @override
    void didChangeDependencies() {
        if (!_isInit) {
        _isLoading = true;
        Provider.of<Items>(context).fetchAndSetItems().then((_) {
            setState(() {
            _isLoading = false;
            });
        });
        }

        _isInit = true;
        super.didChangeDependencies();
    }
    ```

    - now lets refactor `body` in `Scaffold` widget :
    ```
    body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : ItemsGrid(),
    ```

    - we get error beacuse `ItemsGrid` is not exist, we need to create it

<details>
    <summary>items_overview_screen.dart</summary>

    class ItemsOverviewScreen extends StatefulWidget {
    @override
    _ProductsOverviewScreenState createState() => _ProductsOverviewScreenState();
    }

    class _ProductsOverviewScreenState extends State<ItemsOverviewScreen> {
    var _isInit = false;
    var _isLoading = false;

    @override
    void didChangeDependencies() {
        if (!_isInit) {
        _isLoading = true;
        Provider.of<Items>(context).fetchAndSetItems().then((_) {
            setState(() {
            _isLoading = false;
            });
        });
        }

        _isInit = true;
        super.didChangeDependencies();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
        appBar: AppBar(
            title: Text('Flutter Workshop'),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(),
                )
            : ItemsGrid(),
        );
    }
    }
</details>

- `ItemsGrid`
    - lets create a file `items_grid.dart` and `StatelessWidget` and call it `ItemsGrid` and import `material.dart`
    - inside build function ,lets get our items from the provider contex

    ```
    final items = Provider.of<Items>(context).items;
    ```

    - we will use another `Flutter` layout widget - `GridView` (A scrollable, 2D array of widgets)
    - `GridView` will take care of the layout for us
    - we will write it in builder way : 
        - `itemCount` - we will pass how many items there are
        - `gridDelegate` (produce an arbitrary 2D arrangement of children) - we will pass `SliverGridDelegateWithFixedCrossAxisCount`
        - `itemBuilder` - we need to loop over items and return `ItemWidget`

        ```
        GridView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: items.length,
            itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
                value: items[i],
                child: Container(
                child: ItemWidget(),
                ),
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
            ),
        );
        ```
- we get error beacuse `ItemWidget` is not exist, we need to create it

<details>
<summary>items_grid.dart</summary>

    import 'package:flutter/material.dart';
    import 'package:provider/provider.dart';
    import '../widgets/item_widget.dart';

    import '../providers/items.dart';

    class ItemsGrid extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        final items = Provider.of<Items>(context).items;
        
        return GridView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: items.length,
        itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
            value: items[i],
            child: Container(
            child: ItemWidget(),
            ),
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
        ),
        );
    }
    }

</details>

- `ItemWidget`
    - lets crate `item_widget.dart` and `StatelessWidget` named `ItemWidget` and import `material.dart`
    - we will need to use `Assets` this time - lets add import in `pubspec.yaml` file 
    ```
    assets:
     - assets/images/wix-logo.jpg
   ```
    - inside build function ,we will take our item from `Item` provider

    ```
    final item = Provider.of<Item>(context, listen: false);
    ```
    - we will use now `ClipRRect` another Flutter build in widget (clips its child using a rounded rectangle, similar to `ClipOval`and `ClipPath`)

        - we will pass it borderRadius of 10
        - and his child will be `GridTile` which is grid tile part of `GridView` list, (we are using `GridView` in our `ItemsWidget`)
        - now we will cover the child with `Hero` widget, so we will have a nice hero animation (A widget that marks its child as being a candidate for hero animations)

            - we need to add `tag` propety so it will know which widget should get the hero animation, you need to add identical tag for both of them (widget where the animation trrigers and the widget where is should haapen)

            - the child will be `FadeInImage` widget(An image that shows a placeholder image while the target image is loading, then fades in the new image when it loads)
            - the palce order will be from our assets images 
                ```
                AssetImage('assets/images/wix-logo.jpg')```

            - image propetry : will use `FileImage` widget that will laod the image with `File` widget from `dart:io` - im port it 

                ```
                import 'dart:io';
                .
                .
                .
                .
                FileImage(item.image)
                .
                .
                .
                ```
            - and fit propetry `BoxFit.cover`

        - we will add fotter and it will be `GridTileBar`

            ```
            backgroundColor: Colors.black87,
                title: Text(
                    item.title,
                    textAlign: TextAlign.center,
                ),
            ```

        now we can import `ItemWidget` in `ItemsGrid` 

<details>
    <summary>item_widget.dart</summary>
    import 'dart:io';
    import 'package:flutter/material.dart';
    import 'package:provider/provider.dart';
    import '../providers/item.dart';

    class ItemWidget extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        final item = Provider.of<Item>(context, listen: false);

        return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GridTile(
            child: GestureDetector(
            onTap: () {
            },
            child: Hero(
                tag: item.id,
                child: FadeInImage(
                placeholder: AssetImage('assets/images/wix-logo.jpg'),
                image: FileImage(item.image),
                fit: BoxFit.cover,
                ),
            ),
            ),
            footer: GridTileBar(
            backgroundColor: Colors.black87,
            title: Text(
                item.title,
                textAlign: TextAlign.center,
            ),
            ),
        ),
        );
    }
    }

</details>

## item overiew screen

 - lets cretae new file `item_detail_screen.dart`
 - this widget screen will show more dutails about the item
    - bigger image
    - details about the item

first lets create `StatelessWidget` with name `ItemDetailScreen`

- add route to the file , that way we could approach it

```
    static const routeName = '/item-detail';
```

- we will need to get the item id somehow so we will be able to show the right item data - so we will use `context`

    - when you navigate from `ItemOverviewScreen` (acutally `ItemWidget`) by clicking on the item , you can pass `arguments` so in `ItemDetailScreen` we will be able to use them. we will pass the item Id that way.

lets add to `onTap` function in `ItemWidget` which will pass `argumants` - `item.id` inside:

```
    Navigator.of(context).pushNamed(
              ItemDetailScreen.routeName,
              arguments: item.id,
            );
```

 - and now, we will add to `ItemDetailScreen` a call to the `ModalRoute` , so it would be able to get the `itemId` from the arguments, then we'll use it to get the right item from `Items Provider`

 ```
 final itemId = ModalRoute.of(context).settings.arguments as String;
 final loadedItem = Provider.of<Items>(
      context,
      listen: false,
    ).findById(itemId);

 ``` 
after getting the in fostructre ready, lets add our screen detail ui 

- we will return `Scaffold`
- it will contain our second part of the `Hero` animation 
- we will have a new widget -  `CustomScrollView` (A ScrollView that creates custom scroll effects using slivers) for a cool scroll
    - it will be divided for two parts :
        - slivers - inside it will contain `SliverAppBar` (A material design app bar that integrates with a CustomScrollView). which be containing our `Hero` widget as `background`, with title of the item
        - SliverList - which will contin more details about the item 

<details>
    <summary>UI</summary>

    return Scaffold(
        body: CustomScrollView(
            slivers: <Widget>[
            SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                title: Text(loadedItem.title),
                background: Hero(
                    tag: loadedItem.id,
                    child: Image.file(
                    File(
                        loadedItem.image.path,
                    ),
                    fit: BoxFit.cover,
                    ),
                ),
                ),
            ),
            SliverList(
                delegate: SliverChildListDelegate(
                [
                    SizedBox(
                    height: 10,
                    ),
                    Text(
                    '\$${loadedItem.price}',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                    ),
                    SizedBox(
                    height: 10,
                    ),
                    Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    width: double.infinity,
                    child: Text(
                        loadedItem.description,
                        textAlign: TextAlign.center,
                        softWrap: true,
                    ),
                    ),
                    SizedBox(
                    height: 800,
                    ),
                ],
                ),
            ),
            ],
        ),
        );
</details>

 thats it , now it suppose to work - try by clicking on the item!

 <details>
 <summary>item_detail_screen.dart</summary>
 import 'dart:io';

    import 'package:flutter/material.dart';
    import 'package:provider/provider.dart';

    import '../providers/items.dart';

    class ItemDetailScreen extends StatelessWidget {
    static const routeName = '/item-detail';

    @override
    Widget build(BuildContext context) {
        final itemId = ModalRoute.of(context).settings.arguments as String;
        final loadedItem = Provider.of<Items>(
        context,
        listen: false,
        ).findById(itemId);

        return Scaffold(
        body: CustomScrollView(
            slivers: <Widget>[
            SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                title: Text(loadedItem.title),
                background: Hero(
                    tag: loadedItem.id,
                    child: Image.file(
                    File(
                        loadedItem.image.path,
                    ),
                    fit: BoxFit.cover,
                    ),
                ),
                ),
            ),
            SliverList(
                delegate: SliverChildListDelegate(
                [
                    SizedBox(
                    height: 10,
                    ),
                    Text(
                    '\$${loadedItem.price}',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                    ),
                    SizedBox(
                    height: 10,
                    ),
                    Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    width: double.infinity,
                    child: Text(
                        loadedItem.description,
                        textAlign: TextAlign.center,
                        softWrap: true,
                    ),
                    ),
                    SizedBox(
                    height: 800,
                    ),
                ],
                ),
            ),
            ],
        ),
        );
    }
    }

 </details>

## Add Button and Add Item Screen

- lets add add button to our main screen `ItemsOverviewScreen` 
- in `Scaffold` we need to add another property `floatingActionButton`, inside of it we will use `FloatingActionButton` widget 
    - in `onPressed` function we will have navigation to our new widget `addItem` - `AddItemScreen.routeName`

```
floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AddItemScreen.routeName);
        },
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
```  

- lets create `AddItemScreen` - create file `add_item_screen.dart`
- it will be `StatefulWidget`
- dont forget to import `'package:flutter/material.dart'`
- we need to add its rout to the routs in `main.dart` file
- also we need to create  route to `addItemScreen` screen
```
static const routeName = '/add-item';
```

- we need to add to `main.dart` route to `AddItemScreen`

```
 AddItemScreen.routeName: (ctx) => AddItemScreen(),
```
- go to `items.dart` and add the code below , it would be usefull later

```
import 'package:path/path.dart' as path;
...
...
...
Future<void> addItem(Item item) async {
    final url = '$baseUrl/items.json?auth=$authToken';
    try {
      print(path.basename(item.image.path));
      print(path.extension(item.image.path));
      final response = await http.post(url,
          body: json.encode({
            'title': item.title,
            'description': item.description,
            'price': item.price,
            'creatorId': userId,
            'image': path.basename(item.image.path)
          }));

      await uploadPic(item.image);

      final newItem = Item(
          title: item.title,
          description: item.description,
          price: item.price,
          id: json.decode(response.body)['name'],
          image: item.image);

      _items.add(newItem);
    } catch (error) {
      throw error;
    }
  }

Future<void> uploadPic(File image) async {
    String fileName = path.basename(image.path);
    StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = firebaseStorageRef.putFile(image);
    uploadTask.onComplete;
  }
```

- now we can start working on `AddItemScreen` logic an ui
    - we will have a `Form` widget for the inputs (handling the input + validations)

- Inside `_AddItemScreenState`
- we need to create `GlobalKey` for the form state (Global keys uniquely identify elements. Global keys provide access to other objects that are associated with those elements, such as BuildContext. For StatefulWidgets, global keys also provide access to State)
- we will have init values for the inputs and empty `Item` variable

- we will use `TextFormField` widget for the simple text inputs , and for the user to jump easly between the inputs we will use `focusNode` properties, we need to initate them
- lets add `isLoading` and `isInit` vaible also to use later

```
  final _form = GlobalKey<FormState>();
  final _descriptionFocusNode = FocusNode();

  final _priceFocusNode = FocusNode();
  File _pickedImage;

var _addItem = Item(
    id: null,
    title: '',
    price: 0,
    description: '',
    image: null,
  );

  var _initValues = {
    'title': '',
    'description': '',
    'price': '',
    'image': '',
  };

  var _isInit = true;
  var _isLoading = false;

```
- UI
    - we will returen `Scaffold` widget 

```
return Scaffold(
      appBar: AppBar(
        title: Text('Add New Item'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveForm,
          )
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _form,
                child: ListView(
                  children: <Widget>[
                      ....
                      ....
                      ....
```

- lets add all the inputs here 
    - form lets us use onSubmit function for all the inputs inside of it, therefore we will have in each `TextFieldInput` `onSave` function to handle it self when it got submitted
    - also each one will have `initValue` property 
    - `decoration` property will be his title 
    - `onFieldSubmitted` property will be moving between inputs after submiting one
    - `validator` will get value and check our custome ruls about it 

    ```
    TextFormField(
                      initialValue: _initValues['title'],
                      decoration: InputDecoration(labelText: 'Title'),
                      textInputAction: TextInputAction.next,
                      onSaved: (value) => _addItem = Item(
                        title: value,
                        id: _addItem.id,
                        isFavorite: _addItem.isFavorite,
                        price: _addItem.price,
                        description: _addItem.description,
                        image:
                            _pickedImage != null ? _pickedImage : _addItem,
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please provide a value';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_priceFocusNode),
                    ),
    ```

    - please create also `price` and `description` textFields 

    <details>
    <summary>inputs</summary>
                    TextFormField(
                      initialValue: _initValues['price'],
                      decoration: InputDecoration(labelText: 'Price'),
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      focusNode: _priceFocusNode,
                      onSaved: (value) => _addItem = Item(
                        title: _addItem.title,
                        id: _addItem.id,
                        isFavorite: _addItem.isFavorite,
                        price: double.parse(value),
                        description: _addItem.description,
                        image:
                            _pickedImage != null ? _pickedImage : _addItem,
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Please enter a number greter then zero';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => FocusScope.of(context)
                          .requestFocus(_descriptionFocusNode),
                    ),
                    TextFormField(
                      initialValue: _initValues['description'],
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      onSaved: (value) => _addItem = Item(
                        title: _addItem.title,
                        id: _addItem.id,
                        isFavorite: _addItem.isFavorite,
                        price: _addItem.price,
                        description: value,
                        image:
                            _pickedImage != null ? _pickedImage : _addItem,
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please provide a description';
                        }
                        if (value.length < 10) {
                          return 'Should be at least 10 charectersling';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.multiline,
                      focusNode: _descriptionFocusNode,
                    ),
    </details>

- now we just need to create `ImageInput`
    - lets create new file in inputs folder we have `image_input.dart`
    - it will be `Stateful` widget
    - it will get `onSelectImage` function from `AddItemScreen` so it would be avialable in the form
    - dont forget to import `import package:flutter/material.dart`
    - we will use `image_picker` package.
    
    - lets create `takePicture` function , which will take picture with phone camera , and  `storedImage` variable

```        
         File _storedImage;

        _takePicture() async {
            final imageFile = await ImagePicker.pickImage(
            source: ImageSource.camera,
            maxWidth: 600,
            );

            if (imageFile == null) {
            return;
            }
            setState(() {
            _storedImage = imageFile;
            });

            widget.onSelectImage(imageFile);
        }
```

- now add this code for the ui 

    ```
        return Row(
            children: <Widget>[
                Container(
                width: 150,
                height: 100,
                decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.grey),
                ),
                child: _storedImage != null
                    ? Image.file(
                        _storedImage,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        )
                    : Text(
                        'No Image Taken',
                        textAlign: TextAlign.center,
                        ),
                alignment: Alignment.center,
                ),
                SizedBox(width: 10),
                Expanded(
                child: FlatButton.icon(
                    icon: Icon(Icons.camera),
                    label: Text('Take picture'),
                    textColor: Theme.of(context).primaryColor,
                    onPressed: _takePicture,
                ),
                ),
            ],
        );
    ```

     - `onPressed` will trriger `_takePicture` function , and then will update `AddItemScreen` form

    <details>
    <summary>image_input.dart</summary>

            import 'dart:io';

            import 'package:flutter/material.dart';
            import 'package:image_picker/image_picker.dart';

            class ImageInput extends StatefulWidget {
            final Function onSelectImage;
            ImageInput(this.onSelectImage);

            @override
            _ImageInputState createState() => _ImageInputState();
            }

            class _ImageInputState extends State<ImageInput> {
            File _storedImage;

            _takePicture() async {
                final imageFile = await ImagePicker.pickImage(
                source: ImageSource.camera,
                maxWidth: 600,
                );

                if (imageFile == null) {
                return;
                }
                setState(() {
                _storedImage = imageFile;
                });

                widget.onSelectImage(imageFile);
            }

            @override
            Widget build(BuildContext context) {
                return Row(
                children: <Widget>[
                    Container(
                    width: 150,
                    height: 100,
                    decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Colors.grey),
                    ),
                    child: _storedImage != null
                        ? Image.file(
                            _storedImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            )
                        : Text(
                            'No Image Taken',
                            textAlign: TextAlign.center,
                            ),
                    alignment: Alignment.center,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                    child: FlatButton.icon(
                        icon: Icon(Icons.camera),
                        label: Text('Take picture'),
                        textColor: Theme.of(context).primaryColor,
                        onPressed: _takePicture,
                    ),
                    ),
                ],
                );
            }
            }

    </details>

    - back to the form , ltes add image input under the others inputs 
    - and create _selectImage function
    ```
    Container(
                      width: 100,
                      height: 100,
                      margin: EdgeInsets.only(top: 8, right: 10),
                      child: ImageInput(_selectImage),
                    ),
    ```

    - lets create `_saveForm` function , it will validate our inputs and then will add new item to our firebase
    - it will show loader while we are wating for response
    - in case of error it will show `AlertDialog`
    - after it will finish all steps it will close `AddItemScreen` (will use Navigator.of(context).pop())

    <details>
    <summary>_saveForm</summary>

        Future<void> _saveForm() async {
            final isValid = _form.currentState.validate();
            if (!isValid) {
            return;
            }
            _form.currentState.save();
            setState(() {
            _isLoading = true;
            });
            try {
            await Provider.of<Items>(context, listen: false).addItem(_addItem);
            } catch (error) {
            await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                title: Text('An error occurred'),
                content: Text(error.toString()), //some thing went wrong
                actions: <Widget>[
                    FlatButton(
                    child: Text('Okay'),
                    onPressed: () {
                        Navigator.of(context).pop();
                    },
                    )
                ],
                ),
            );
            }

            setState(() {
            _isLoading = false;
            });
            Navigator.of(context).pop();
        }

    </details>

- all left to so it to `dispose` all elements of focusNode in `dispose` time (Called when this object is removed from the tree permanently) 

```
@override
  void dispose() {
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }
```

<details>
    <summary>add_item_screen.dart</summary>

            import 'dart:io';

    import 'package:flutter/material.dart';
    import 'package:provider/provider.dart';
    import 'package:test_proj/providers/item.dart';
    import '../providers/items.dart';

    class AddItemScreen extends StatefulWidget {
    static const routeName = '/add-item';
    @override
    _AddItemScreenState createState() => _AddItemScreenState();
    }

    class _AddItemScreenState extends State<AddItemScreen> {
    final _form = GlobalKey<FormState>();
    final _descriptionFocusNode = FocusNode();

    final _priceFocusNode = FocusNode();
    File _pickedImage;

    void _selectImage(File pickedImage) {
        _pickedImage = pickedImage;
    }

    var _addItem = Item(
        id: null,
        title: '',
        price: 0,
        description: '',
        image: null,
    );

    var _initValues = {
        'title': '',
        'description': '',
        'price': '',
        'image': '',
    };

    var _isInit = true;
    var _isLoading = false;

    @override
    void dispose() {
        _priceFocusNode.dispose();
        _descriptionFocusNode.dispose();
        super.dispose();
    }

    Future<void> _saveForm() async {
        final isValid = _form.currentState.validate();
        if (!isValid) {
        return;
        }
        _form.currentState.save();
        setState(() {
        _isLoading = true;
        });
        try {
        await Provider.of<Items>(context, listen: false).addItem(_addItem);
        } catch (error) {
        await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
            title: Text('An error occurred'),
            content: Text(error.toString()), //some thing went wrong
            actions: <Widget>[
                FlatButton(
                child: Text('Okay'),
                onPressed: () {
                    Navigator.of(context).pop();
                },
                )
            ],
            ),
        );
        }

        setState(() {
        _isLoading = false;
        });
        Navigator.of(context).pop();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
        appBar: AppBar(
            title: Text('Add New Item'),
            actions: <Widget>[
            IconButton(
                icon: Icon(Icons.save),
                onPressed: _saveForm,
            )
            ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(),
                )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                    key: _form,
                    child: ListView(
                    children: <Widget>[
                        TextFormField(
                        initialValue: _initValues['title'],
                        decoration: InputDecoration(labelText: 'Title'),
                        textInputAction: TextInputAction.next,
                        onSaved: (value) => _addItem = Item(
                            title: value,
                            id: _addItem.id,
                            isFavorite: _addItem.isFavorite,
                            price: _addItem.price,
                            description: _addItem.description,
                            image:
                                _pickedImage != null ? _pickedImage : _addItem,
                        ),
                        validator: (value) {
                            if (value.isEmpty) {
                            return 'Please provide a value';
                            }
                            return null;
                        },
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_priceFocusNode),
                        ),
                        TextFormField(
                        initialValue: _initValues['price'],
                        decoration: InputDecoration(labelText: 'Price'),
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        focusNode: _priceFocusNode,
                        onSaved: (value) => _addItem = Item(
                            title: _addItem.title,
                            id: _addItem.id,
                            isFavorite: _addItem.isFavorite,
                            price: double.parse(value),
                            description: _addItem.description,
                            image:
                                _pickedImage != null ? _pickedImage : _addItem,
                        ),
                        validator: (value) {
                            if (value.isEmpty) {
                            return 'Please enter a price';
                            }
                            if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                            }
                            if (double.parse(value) <= 0) {
                            return 'Please enter a number greter then zero';
                            }
                            return null;
                        },
                        onFieldSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(_descriptionFocusNode),
                        ),
                        TextFormField(
                        initialValue: _initValues['description'],
                        decoration: InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                        onSaved: (value) => _addItem = Item(
                            title: _addItem.title,
                            id: _addItem.id,
                            isFavorite: _addItem.isFavorite,
                            price: _addItem.price,
                            description: value,
                            image:
                                _pickedImage != null ? _pickedImage : _addItem,
                        ),
                        validator: (value) {
                            if (value.isEmpty) {
                            return 'Please provide a description';
                            }
                            if (value.length < 10) {
                            return 'Should be at least 10 charectersling';
                            }
                            return null;
                        },
                        keyboardType: TextInputType.multiline,
                        focusNode: _descriptionFocusNode,
                        ),
                        Container(
                        width: 100,
                        height: 100,
                        margin: EdgeInsets.only(top: 8, right: 10),
                        child: ImageInput(_selectImage),
                        ),
                    ],
                    ),
                ),
                ),
        );
    }
    }
</details>

## App Drawer

so we are starting to have a lot of screens, we should make navigation between them be easy - lets make navigation menu which be `App Drawer`

- for start it will have buttons for `Logout` and `Home` navigation
- lets create `app_drawer.dart` in widgets folder , and create `StatelessWidget` called `AppDrawer`
- it will return `Drawer` widget (A material design panel that slides in horizontally from the edge of a Scaffold to show navigation links in an application)
     - inside `Drawer` we will return `Column` widget with some widgets:
        - `AppBar` with `title` and inside it  (An app bar consists of a toolbar and potentially other widgets, such as a TabBar and a FlexibleSpaceBar. App bars typically expose one or more common actions with IconButtons which are optionally followed by a PopupMenuButton for less common operations (sometimes called the "overflow menu"))

        ```
        AppBar(
                title: Text('Flutter Wix Workshop'),
                automaticallyImplyLeading: false,
            ),
        ```

        - `Divider` (A thin horizontal line, with padding on either side)
        - `ListTile` (A single fixed-height row that typically contains some text as well as a leading or trailing icon)
        it will contain the `Icon` ,`Text` and `onTap`.
        - we will make two sets of `Divider` + `ListTile` for `Logout` and `Home`
        ```
        Divider(),
            ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Logout'),
                onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/');
                Provider.of<Auth>(context, listen: false).logout();
                },
            ),
        ```

        - create one for `Home` with home icon. `onTap` will navigate to `ItemsOvwerviewScreen` (it will `pushReplacementNamed` and not just `push` the rout)

<details>
<summary>app_drawer.dart</summary>

    import 'package:flutter/material.dart';
    import 'package:provider/provider.dart';

    import '../providers/auth.dart';

    class AppDrawer extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return Drawer(
        child: Column(
            children: <Widget>[
            AppBar(
                title: Text('Flutter Wix Workshop'),
                automaticallyImplyLeading: false,
            ),
            Divider(),
            ListTile(
                leading: Icon(Icons.home),
                title: Text('Home'),
                onTap: () {
                Navigator.of(context).pushReplacementNamed('/');
                },
            ),
            Divider(),
            ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Logout'),
                onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/');
                Provider.of<Auth>(context, listen: false).logout();
                },
            ),
            ],
        ),
        );
    }
    }
</details>

- now lets start using our new `AppDrawer`
- add `appDrawer` property to `Scafolled` on top of `body` property in `itemsOverViewScreen` 
```
drawer: AppDrawer(),
```

## Mange Items Screen

- lets create `mange_items_screen.dart` in screens folder , and create `StatelessWidget` called `MangeItemsScreen`
- lets add route to it just like before
    ```
    static const routeName = '/user-items';
    ```
- in this page we will show **only** items which the logged in user created
- we will pass `filterByUser` true to `fetchAndSetItems` function in the `items provider`
- lets add `_refreshItems` function to our widget (Widget that builds itself based on the latest snapshot of interaction with a Future)
    - it will trigger each time `_refreshItems` function with the `contex`


```
  Future<void> _refreshItems(BuildContext context) async {
    await Provider.of<Items>(context, listen: false).fetchAndSetItems(true);
  }
```
- we will return `Scaffold`  widget with `AppBar`(which will contain `IconButton` with `add` icon and `onPressed` function which will navigate us to `AddItemScreen`) widget and with our `appDrawer`
```
appBar: AppBar(
        title: Text('Your Items'),
        actions: <Widget>[
            IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                Navigator.of(context).pushNamed(AddItemScreen.routeName);
                },
            )
            ],
      ),
      drawer: AppDrawer(),
```
- in `body` we will have `FutureBuilder` widget 
    - it will contain two properties : `future` and `builder`
    - the builder will get called first when the widget is renderd(we will show `CircularProgressIndicator` widget for it) , then when the future will finish and we will get response, it will handle it, and we will get to show the items.

```
body: FutureBuilder(
        future: _refreshItems(context),
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.waiting
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : RefreshIndicator(
                    onRefresh: () => _refreshItems(context),
                    child: Consumer<Items>(
                      builder: (context, itemsData, _) => Padding(
                        padding: EdgeInsets.all(8),
                        child: ListView.builder(
                          itemCount: itemsData.items.length,
                          itemBuilder: (_, i) => Column(
                            children: <Widget>[
                              .
                              .
                              .
                              .
                              .
                              Divider(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
```
- now we are missing a widget for the `items` data we have , so lets create one
- it will be called `ManageItemView`

- lets create `mange_item_view.dart` in widgets folder , and create `StatelessWidget` called `ManageItemView` 
- it will get id, title, and image as class properties
```
  final String id;
  final String title;
  final File image;

  ManageItemView(this.id, this.title, this.image);
``` 
- we will return `ListTile` widget (A single fixed-height row that typically contains some text as well as a leading or trailing icon)
    - it will contain `title`, `leading` and `trailing` properties
    - `title` will be `Text` widget with the title we got 
    - `leading` will be `CircleAvatar` widget with `backgroundImage` with the Image we got
    - `trailing` will return `Container` widget , for now it will return empty `Row` widget

    ```
    return ListTile(
        title: Text(title),
        leading: CircleAvatar(
            backgroundImage: FileImage((image)),
        ),
        trailing: Container(
            width: 100,
            child: Row(
            children: <Widget>[
            ],
            ),
        ),
        );
    ```

<details>
<summary>mange_item_view.dart</summary>

    import 'dart:io';

    import 'package:flutter/material.dart';
    import 'package:provider/provider.dart';
    import 'package:workshop1/screens/edit_item_screen.dart';
    import '../providers/items.dart';

    class ManageItemView extends StatelessWidget {
    final String id;
    final String title;
    final File image;

    ManageItemView(this.id, this.title, this.image);

    @override
    Widget build(BuildContext context) {
        return ListTile(
        title: Text(title),
        leading: CircleAvatar(
            backgroundImage: FileImage((image)),
        ),
        trailing: Container(
            width: 100,
            child: Row(
            children: <Widget>[
            ],
            ),
        ),
        );
    }
    }

</details>

- lets fill up the code that missing in `MangeItemsScreen` in the `itemBuilder childern` - 

```
 ManageItemView(
        itemsData.items[i].id,
        itemsData.items[i].title,
        itemsData.items[i].image,
    ),
``` 

- lets add button for our manage page in the `AppDrawer`, under `home` button we will add `Divider` and `ListTile` with 'Mange Items' text

```
          Divider(),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Mange Items'),
            onTap: () {
              Navigator.of(context)
                  .pushReplacementNamed(ManageItemsScreen.routeName);
            },
          ),
```

- and we need to add the rout to `main.dart` file 
```
ManageItemsScreen.routeName: (ctx) => ManageItemsScreen(),
``` 

<details>
<summary>mange_items_screen.dart</summary>

    import 'package:flutter/material.dart';
    import 'package:provider/provider.dart';
    import 'package:workshop1/screens/edit_item_screen.dart';
    import 'package:workshop1/widgets/user_item_view.dart';

    import '../widgets/app_drawer.dart';
    import '../providers/items.dart';

    class UserItemsScreen extends StatelessWidget {
    static const routeName = '/user-items';

    Future<void> _refreshItems(BuildContext context) async {
        await Provider.of<Items>(context, listen: false).fetchAndSetItems(true);
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
        appBar: AppBar(
            title: Text('Your Items'),
            actions: <Widget>[
            IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                Navigator.of(context).pushNamed(AddItemScreen.routeName);
                },
            )
            ],
        ),
        drawer: AppDrawer(),
        body: FutureBuilder(
            future: _refreshItems(context),
            builder: (context, snapshot) =>
                snapshot.connectionState == ConnectionState.waiting
                    ? Center(
                        child: CircularProgressIndicator(),
                    )
                    : RefreshIndicator(
                        onRefresh: () => _refreshItems(context),
                        child: Consumer<Items>(
                        builder: (context, itemsData, _) => Padding(
                            padding: EdgeInsets.all(8),
                            child: ListView.builder(
                            itemCount: itemsData.items.length,
                            itemBuilder: (_, i) => Column(
                                children: <Widget>[
                                ManageItemView(
                                    itemsData.items[i].id,
                                    itemsData.items[i].title,
                                    itemsData.items[i].image,
                                ),
                                Divider(),
                                ],
                            ),
                            ),
                        ),
                        ),
                    ),
        ),
        );
    }
    }

</details>

## Delete Item

lets start with adding this code to `items.dart` which will remove items from our server

```
Future<void> deleteItem(String id) async {
    final url = '$baseUrl/items/$id.json?auth=$authToken';
    final existingItemIndex = _items.indexWhere((item) => item.id == id);
    var existingItem = _items[existingItemIndex];

    _items.removeAt(existingItemIndex);
    notifyListeners();

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingItemIndex, existingItem);
      notifyListeners();
      throw HttpException('Could not delete item');
    } else {
      existingItem = null;
    }
  }
 ```

- and now lets add button in `ManageItemView` which will remove the item when clicked
    - under `trailing -> children widgets` , we will add `IconButton` widget  who will be with icon `Icons.delete`
    - `onPressed` will call our new function in `Items` provider , it will get `id` of item that will be removed
    - `listen: false` will get value once and ignore updates (we don't need more)
    - in case of error we will show snackBar 
        - we need to get Scaffold from the context for that (under widget `build` function we will add it)

        ```
        final scaffold = Scaffold.of(context);
        ```
<details>
    <summary>IconButton</summary>


    IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                try {
                  Provider.of<Items>(context, listen: false).deleteItem(id);
                } catch (error) {
                  scaffold.showSnackBar(SnackBar(
                    content: Text(
                      'Deleteing faild!',
                      textAlign: TextAlign.center,
                    ),
                  ));
                }
              },
              color: Theme.of(context).errorColor,
            )

</details>

# Bonus Part: Edit item , Like button

## Like Button

lets add like button on the item in our home screen

- first lets add the function we need in our `Item` provider (this time not `Items` provider)
- it will update item `isFavorite` staus in server for us
```
final String baseUrl = 'https://flutter-workshop-eef86.firebaseio.com';

  void _setFavoriteValue(bool newValue) {
    isFavorite = newValue;
    notifyListeners();
  }

  Future<void> toggleFavoriteStatus(String token, String userId) async {
    final oldStatus = isFavorite;
    isFavorite = !isFavorite;
    notifyListeners();
    final url = '$baseUrl/userFavorites/$userId/$id.json?auth=$token';
    try {
      final response = await http.put(url,
          body: json.encode(
            isFavorite,
          ));
      if (response.statusCode >= 400) {
        _setFavoriteValue(oldStatus);
      }
    } catch (error) {
      _setFavoriteValue(oldStatus);
      throw error;
    }
  }
```

- lets add new button for it in `ItemWidget`
- we need first to get `authData` from `AuthProvider` 
    - we need to add this line of code under `build` function
    ```
    final authData = Provider.of<Auth>(context, listen: false);
    ```
- now lets add `leading` property inside our footer `GridTileBar` widget 
- it will be `Consumer` widget , it will listen to `Item` provider
- it will hold inside `builder` function `IconButton` which will show `Icons.favorite` or `Icons.favorite_border` (depens if its liked or not)
- `onPressed` will trriget `toggleFavoriteStatus` function 
    - we need to pass `authData.token` and `authData.userId`


<details>
<summary>like button</summary>

    leading: Consumer<Item>(
            builder: (ctx, item, child) => IconButton(
              icon: Icon(
                  item.isFavorite ? Icons.favorite : Icons.favorite_border),
              color: Theme.of(context).accentColor,
              onPressed: () {
                item.toggleFavoriteStatus(
                  authData.token,
                  authData.userId,
                );
              },
            ),
          ),

</details>

- lets add popup manue to select ig we want to show only favorites items
- in `ItemsOverviewScreen` we will add `actions` property in `AppBar` widget
- we will use `PopupMenuButton` widget (Displays a menu when pressed and calls onSelected when the menu is dismissed because an item was selected. The value passed to onSelected is the value of the selected menu item)
    - `onSelect` will get slected value and will check if `_showOnlyFavorites` should be true or false
    - icon property will be `Icons.more_vert`
    - itemBuilder property will be `PopupMenuItem`
        - one will be `Only Favorites` with value of `FilterOptions.Favorites` and another one will be `Show All` with value of `FilterOptions.All`

    - we need to add `enum FilterOptions` ,lets add it on top of our class 
    ```
    enum FilterOptions { Favorites, All }
    ```
- we need to add to `Items` provider 
```
  List<Item> get favoritesItems {
    return _items.where((productItem) => productItem.isFavorite).toList();
  }
```
- now lets pass _showFavorites to `ItemsGrid`
- inside `ItemsGrid` we will add `showOnlyFavorites` property to the class
```
final bool showOnlyFavorites;

ItemsGrid(this.showOnlyFavorites);
```
- now we just need to get the right product according to the `showFavorites` property 
```
final productsData = Provider.of<Products>(context);
    final prodcuts =
        showOnlyFavorites ? productsData.favoritesItems : productsData.items;
```
- now we just to update `fetchAndSetItems` at `Items` provider

```
Future<void> fetchAndSetItems([bool filterByUser = false]) async {
    final filterUrl =
        filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url = '$baseUrl/items.json?auth=$authToken&$filterUrl';
    print(authToken);
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      } else {
        final url =
            'https://flutter-course-9a6bf.firebaseio.com/userFavorites/$userId.json?auth=$authToken';
        final favoriteResponse = await http.get(url);
        final favoriteData = json.decode(favoriteResponse.body);
        final List<Item> loadedItems = [];
        for (var entry in extractedData.entries) {
          var file = await downloadImage(entry.value['image']);
          Future.delayed(const Duration(milliseconds: 20), () => "20");
          loadedItems.add(Item(
            id: entry.key,
            title: entry.value['title'],
            description: entry.value['description'],
            price: entry.value['price'],
            isFavorite: favoriteData == null ? false : favoriteData[entry.key] ?? false,
            image: file,
          ));
        }
        _items = loadedItems;

        notifyListeners();
      }
    } catch (error) {
      throw error;
    }
  }
```

<details>
<summary>PopupMenuButton</summary>

    actions: <Widget>[
          PopupMenuButton(
            onSelected: (FilterOptions selectedValue) {
              setState(() {
                if (selectedValue == FilterOptions.Favorites) {
                  _showOnlyFavorites = true;
                } else {
                  _showOnlyFavorites = false;
                }
              });
            },
            icon: Icon(
              Icons.more_vert,
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                  child: Text('Only Favorites'),
                  value: FilterOptions.Favorites),
              PopupMenuItem(child: Text('Show All'), value: FilterOptions.All),
            ],
          )
        ],
</details>
with this setup we can finnlly start codeing :raised_hands: 

this will be helpful later.
## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

- login and register ^
- home screen ^
  - post component -  without like - share ^
  - list of items from server - get data and display ^
- item overview screen
  - item overview screen component ^
  - transitions animations and scroll ^
- add button ^
  - add post screen ^
  - validation ^
  - take a picutre ^
- app drawer ^
  - logout ^
- mange screen ^
  - menu items (mange in appdrawer) ^
  - remove post ^
  - edit screen
- like
  - side bar action button (filters) ^

<details>
<summary>android/app/src/debug/AndroidManifest.xml</summary>

    <manifest xmlns:android="http://schemas.android.com/apk/res/android"
        package="com.example.workshop1">
        <!-- Flutter needs it to communicate with the running application
            to allow setting breakpoints, to provide hot reload, etc.
        -->
        <uses-permission android:name="android.permission.INTERNET"/>
    </manifest>

</details>

<details>
<summary>android/app/src/main/AndroidManifest.xml</summary>

    <manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.workshop1">
    <!-- io.flutter.app.FlutterApplication is an android.app.Application that
         calls FlutterMain.startInitialization(this); in its onCreate method.
         In most cases you can leave this as-is, but you if you want to provide
         additional functionality it is fine to subclass or reimplement
         FlutterApplication and put your custom class here. -->
    <application
        android:name="io.flutter.app.FlutterApplication"
        android:label="test_proj"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    </manifest>
</details>


<details>
<summary>android/app/google-services.json</summary>

    {
    "project_info": {
        "project_number": "90010214377",
        "firebase_url": "https://flutter-workshop-eef86.firebaseio.com",
        "project_id": "flutter-workshop-eef86",
        "storage_bucket": "flutter-workshop-eef86.appspot.com"
    },
    "client": [
        {
        "client_info": {
            "mobilesdk_app_id": "1:90010214377:android:ddb59dc63b8d05de29f578",
            "android_client_info": {
            "package_name": "com.example.sign_in_flutter"
            }
        },
        "oauth_client": [
            {
            "client_id": "90010214377-4r58u39907bavsens11od9sjd6ksisp3.apps.googleusercontent.com",
            "client_type": 1,
            "android_info": {
                "package_name": "com.example.sign_in_flutter",
                "certificate_hash": "0e7e1a2b2f9d992e6a1dee26fd20de2fa0fcf416"
            }
            },
            {
            "client_id": "90010214377-r9a8rf8b46giu27h73l6pmdehb57bk2s.apps.googleusercontent.com",
            "client_type": 3
            }
        ],
        "api_key": [
            {
            "current_key": "AIzaSyA66OELi9lld9M-5VEfC77XSOv-3ksWgmQ"
            }
        ],
        "services": {
            "appinvite_service": {
            "other_platform_oauth_client": [
                {
                "client_id": "90010214377-r9a8rf8b46giu27h73l6pmdehb57bk2s.apps.googleusercontent.com",
                "client_type": 3
                },
                {
                "client_id": "90010214377-jpk8b23p6s5btfvah5f1ahv5tlskc5ol.apps.googleusercontent.com",
                "client_type": 2,
                "ios_info": {
                    "bundle_id": "com.example.signInFlutter"
                }
                }
            ]
            }
        }
        },
        {
        "client_info": {
            "mobilesdk_app_id": "1:90010214377:android:391443a6086b32d729f578",
            "android_client_info": {
            "package_name": "com.example.workshop1"
            }
        },
        "oauth_client": [
            {
            "client_id": "90010214377-jsu3vp1k4d0nluo8v3ju5np6t0smm7mo.apps.googleusercontent.com",
            "client_type": 1,
            "android_info": {
                "package_name": "com.example.workshop1",
                "certificate_hash": "0e7e1a2b2f9d992e6a1dee26fd20de2fa0fcf416"
            }
            },
            {
            "client_id": "90010214377-r9a8rf8b46giu27h73l6pmdehb57bk2s.apps.googleusercontent.com",
            "client_type": 3
            }
        ],
        "api_key": [
            {
            "current_key": "AIzaSyA66OELi9lld9M-5VEfC77XSOv-3ksWgmQ"
            }
        ],
        "services": {
            "appinvite_service": {
            "other_platform_oauth_client": [
                {
                "client_id": "90010214377-r9a8rf8b46giu27h73l6pmdehb57bk2s.apps.googleusercontent.com",
                "client_type": 3
                },
                {
                "client_id": "90010214377-jpk8b23p6s5btfvah5f1ahv5tlskc5ol.apps.googleusercontent.com",
                "client_type": 2,
                "ios_info": {
                    "bundle_id": "com.example.signInFlutter"
                }
                }
            ]
            }
        }
        }
    ],
    "configuration_version": "1"
    }
</details>

<details>
<summary>android/app/build.gradle</summary>

    def localProperties = new Properties()
    def localPropertiesFile = rootProject.file('local.properties')
    if (localPropertiesFile.exists()) {
        localPropertiesFile.withReader('UTF-8') { reader ->
            localProperties.load(reader)
        }
    }

    def flutterRoot = localProperties.getProperty('flutter.sdk')
    if (flutterRoot == null) {
        throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
    }

    def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
    if (flutterVersionCode == null) {
        flutterVersionCode = '1'
    }

    def flutterVersionName = localProperties.getProperty('flutter.versionName')
    if (flutterVersionName == null) {
        flutterVersionName = '1.0'
    }

    apply plugin: 'com.android.application'
    apply plugin: 'com.google.gms.google-services'
    apply plugin: 'kotlin-android'
    apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"

    android {
        compileSdkVersion 28

        sourceSets {
            main.java.srcDirs += 'src/main/kotlin'
        }

        lintOptions {
            disable 'InvalidPackage'
        }

        defaultConfig {
            // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
            applicationId "com.example.workshop1"
            minSdkVersion 16
            targetSdkVersion 28
            versionCode flutterVersionCode.toInteger()
            versionName flutterVersionName
            testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
        }

        buildTypes {
            release {
                // TODO: Add your own signing config for the release build.
                // Signing with the debug keys for now, so `flutter run --release` works.
                signingConfig signingConfigs.debug
            }
        }
    }

    flutter {
        source '../..'
    }

    dependencies {
        implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
        testImplementation 'junit:junit:4.12'
        androidTestImplementation 'androidx.test:runner:1.1.1'
        androidTestImplementation 'androidx.test.espresso:espresso-core:3.1.1'
        implementation 'com.google.firebase:firebase-analytics:17.2.2'
    }

    </details>


    <details>
    <summary>android/build.gradle</summary>

        buildscript {
        ext.kotlin_version = '1.3.50'
        repositories {
            google()
            jcenter()
        }

        dependencies {
            classpath 'com.android.tools.build:gradle:3.5.0'
            classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
            classpath 'com.google.gms:google-services:4.3.3'
        }
    }

    allprojects {
        repositories {
            google()
            jcenter()
        }
    }

    rootProject.buildDir = '../build'
    subprojects {
        project.buildDir = "${rootProject.buildDir}/${project.name}"
    }
    subprojects {
        project.evaluationDependsOn(':app')
    }

    task clean(type: Delete) {
        delete rootProject.buildDir
    }


</details>
<details>
<summary>/android/build.gradle</summary>
buildscript {
    ext.kotlin_version = '1.3.50'
    repositories {
        google()
        jcenter()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:3.5.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath 'com.google.gms:google-services:4.3.3'
    }
}

allprojects {
    repositories {
        google()
        jcenter()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(':app')
}

task clean(type: Delete) {
    delete rootProject.buildDir
}

</details>
<details>
<summary>android/app/src/main/kotlin/com/example/[projectname]/MainActivity.kt</summary>
package com.example.workshop1

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
    }
}

</details>