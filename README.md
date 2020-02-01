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

with this setup we ccan finnlly start codeing :raised_hands: 

this will be helpful later.
## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

- login and register
- home screen
  - post component -  without like - share
  - list of items from server - get data and display
- post screen
  - post screen component
  - transitions animations and scroll
- add button
  - add post screen
  - validation
  - take a picutre
- app drawer
  - menu items (home and mange)
  - logout
- mange screen
  - remove post
  - edit screen
- like
  - side bar action button (filters)
