
# *flutter workshop* :iphone:


## Prerequisites

- follow the instraction - https://flutter.dev/docs/get-started/install/macos (you can skip iOS setup).
- For IDE I recommand to use VSCode - https://code.visualstudio.com/
    - Download flutter extention:
	   in VSCode go to view -> Extainsions -> search for flutter -> install it
	        or
	        <kbd>shift</kbd> <kbd>command</kbd> <kbd>x</kbd> -> search for flutter and install it.
	- Also install mateirial Icon theme - <kbd>shift</kbd> <kbd>command</kbd> <kbd>x</kbd> - search for flutter and install it.
- For phone emolator we will use android studio :
	-  Install android studio(so you can use their emolator) - https://developer.android.com/studio/?gclid=EAIaIQobChMIpo7-tIH75QIVGODtCh127QL1EAAYASAAEgLqi_D_BwE

- now try to create new project - `flutter create --androidx [pick a name for your app]`

By now ,you should be able to run `flutter doctor` on this project and succeed.

---
### :exclamation: note  :exclamation: 
All along doing this workshop you'll have to use emulator - I recomand to use 

***Pixel XL API 28 with Android 9.0(Google APIs)***

(all this project has been tested with it)

---

### :computer: cheat list for VSCode :computer: :notebook:

<kbd>option</kbd> <kbd>shift</kbd> <kbd>F</kbd> -> format your code

<kbd>control</kbd> <kbd>shift</kbd> <kbd>R</kbd> -> helps you when you need to create/change widgets 

# Let's build a Image posting app

- [Prerequisites](#prerequisites)
- [Introduction](#introduction)
- [Step One - Login And register page](#step-one---login-and-register-page)
- [Step Two - Home Screen](#step-two---home-screen)
- [Step Three - Add Button and Add Item Screen](#step-three---add-button-and-add-item-screen)
- [Step Four - App Drawer](#step-four---app-drawer)
- [Step Five - Mangeing Itemsr](#step-five---mangeing-items)
- [Bonus Part: Step Six - Like Button](#bonus-part-like-button)


if you still didn't create new flutter project then run `flutter create --androidx [pick a name for your app]`

after it finish, try to run your new app, in vscode you can click on `debug` -> `start without debuging`
(you can start it from the terminal by runing the command `flutter run`).

### Introduction
First we will have to do some setup , so our project will be ready to develop.
Our app will be using google [`firebase`](https://firebase.google.com/)  for authantication, file storage and database. We won't be learning `firebase` during this workshop, you'll get code snippets for already done integration.

Usually when you start to develop new app (ios or android), you get register as apple developer and register for a Google Play Developer account. Evantually you will register your app in apple store and google play store. During this workshop you wont do it , its already been enabled for you :smirk:

**so lets start** :muscle:

## Step One - Login And Register Page

First step will be to edit `pubspec.yaml` file. 
(Every [pub package](https://dart.dev/guides/packages) needs some metadata so it can specify its [dependencies](https://dart.dev/tools/pub/glossary#dependency).)
this file is like package.json in node. 
You about to add some pub packges in the near future so get ready. 

add this piece of code to `pubspec.yaml` file, under this lines :

```yaml
dependencies:
  flutter:
    sdk: flutter
```

---
### :exclamation: note  :exclamation: 
The indention is realy importent here!
keep all the packges in same space line as `flutter` packege is.

---

```yaml
provider: ^3.1.0
intl: ^0.16.0
http: ^0.12.0+2
shared_preferences: ^0.5.4+3
image_picker: ^0.6.2+1
path_provider: ^1.4.4
firebase_storage: ^3.1.0
```

### project stacture
Lets create some folders, to make our future app arrageable and accsesible. 
our main workplace folder will be `lib`.
we could create all of our `dart` files under it, but we will prefer to make some sub folders, to make it easier and cleaner.

So lets make `screens`, `widgets`, `models` and `providers` folders under `lib` folder.

---
### :exclamation: note  :exclamation: 
any dart file we will create in our project will be in **`snake-case`**

---

now under `models` folder we need to create `http_exception.dart` file and copy this code inside :

```dart
class HttpException implements Exception{
  final String message;
  
  HttpException(this.message);

  @override
  String toString() {
    return message;
  }
}
```

Also under `providers` folder , we need to create `auth.dart` which will have our `Login`, `Signin` and `Logout` logic: 

```dart
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

Now we will change our `main.dart` file, this file controls our app `theme` , app `font` , page lending and our app `routs`. Its basiclly controlls our entire app.

Until now we had deafult config from what `flutter create` made for us,it's time to change it.

we will change `MyApp` class
we can delete `MyHomePage` and `_MyHomePageState`

```dart
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

Please make sure you have both of this lines in top of the page:
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
```

---
### :exclamation: note  :exclamation: 
You'll gonna see this import in almost every file in our app
```dart
import 'package:flutter/material.dart';
```

Its a Flutter widgets implementing Material Design package.
[material.dart package](https://api.flutter.dev/flutter/material/material-library.html) gives us accsses to lots of ready to use widgets (both for ios and android)

---

Now we have some missing widgets and screens -> lets create them.

### Items Overview Screen Widget
Under `screens` folder, create  `items_overview_screen.dart`
    - it will be our first `StatefulWidget` .
if you decided to use vsCode, start writing `st` and it will suggest you whether to create `statefull` widget or `stateless` widget, pick `statefull`.
name the class `ItemsOverviewScreen` .

---
### :exclamation: note  :exclamation: 

any dart class we will create in our project will be in **`camel-case`**

---

make sure to import `material.dart`, we will need to use it's widgets.
instade of returning `container` widget , we will return [`Scaffold`] widget (https://api.flutter.dev/flutter/material/Scaffold-class.html) 
(This widget provides APIs for showing `drawers`, `snack bars`, and `bottom sheets`)

for now we will return scaffold with `appBar` and `body`
   - `appbar` property will be [`AppBar`](https://api.flutter.dev/flutter/material/AppBar-class.html) widget with title
	- `title` will be using [`Text`](https://api.flutter.dev/flutter/widgets/Text-class.html) widget

```dart
	    appBar: AppBar(
	        title: Text('Flutter Workshop'),
	      ),
```

   - `body` property will be for now [`CircularProgressIndicator`](https://api.flutter.dev/flutter/material/CircularProgressIndicator-class.html), ui widget which we can use for loader for now.
(A material design circular progress indicator, which spins to indicate that the application is busy). we will also want our `body` to be center , therfore we will return the `CircularProgressIndicator` inside [`Center`](https://api.flutter.dev/flutter/widgets/Center-class.html) widget
    
    ```dart
    body: Center(
        child: CircularProgressIndicator(),
      ),
    ```

it suppose to look like this :

```dart
   return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Workshop'),
      ),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
```
In `main.dart` file we can use our new widget. we just need to import it at the top of the page :
```
import './screens/Items_overview_screen.dart';
``` 

### Splash Screen Widget
Lets create the `splash_screen` widget
In `screens` folder we need to create `splash_screen.dart`
It will be `stateless` widget.

#### what inside widget :
we will return `Scaffold` widget 
 - `body` property will be `Center` widget and `Text` widget inside of it , with ''Loading...'' as text
 back in `main.dart` we will import it at the top of the page :
```
 import './screens/splash_screen.dart';
```

<details>
		<summary>splash_screen.dart</summary>
	
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
</details>

### Auth Screen Widget
Lets create the `auth_screen` widget
In `screens` folder we need to create `auth_screen.dart`
It will be `StatelessWidget`
Don't forget to import `'package:flutter/material.dart'`
It will return `Scaffold`

***As you can see , each screen widget returns `Scaffold` widget***

#### what inside widget :
- we will use [`Stack`](https://api.flutter.dev/flutter/widgets/Stack-class.html) widget (This widget is useful if you want to overlap several children in a simple way, for example having some text and an image, overlaid with a gradient and a button attached to the bottom)
Inside the `Stack` widget: 
	1. we will have  a `Continer`
	2. [`SingleChildScrollView`](https://api.flutter.dev/flutter/widgets/SingleChildScrollView-class.html) (is used when we want to enable scrolling over a widget (A box in which a single widget can be scrolled))
		- inside `SingleChildScrollView` we will use `Continer` as child , and this time we will have to give it `height` and `width` properties beacuse its inside a `Stack`.
		 we don't want to give it a fixed size like `hight :50, width: 50`
		  it maybe good for our spesific simulator , but we got tons of diffrent phones sizes. 
		 
			 we will use `context` to get th simulator size. 
			inside `Build` function we will add this code : 
				```dart
				final deviceSize = MediaQuery.of(context).size;
				```
		  
				now we can use `deviceSize` as height and width
				```dart
				height: deviceSize.height,
				width: deviceSize.width,
				```
			  
		- `child` propery will be a [`Column`](https://api.flutter.dev/flutter/widgets/Column-class.html) widget (A widget that displays its children in a vertical array).
		- we will want to center our login/sing in widget, therefoe we will add `mainAxisAlignment` and `crossAxisAlignment` properties to our `Column` widgewt
		    ```dart
		    mainAxisAlignment: MainAxisAlignment.center,
		    crossAxisAlignment: CrossAxisAlignment.center,
		    ```
		- now lets use [`Flexible`](https://api.flutter.dev/flutter/widgets/Flexible-class.html) widget which evantually will be title for our auth screen (Flexible is a widget that controls how a child of a Row, Column, or Flex flexes.Using a Flexible widget gives a child of a Row, Column, or Flex the flexibility to expand to fill the available space) 
			- It will have `Container` as a child

			- Lets add some style properties to the `Container` widget  
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
			- The child widget of `Container` will be `Text`, with 'Workshop' as text,
				- Lets add the style property , with `TextStyle` widget inside.
			    - we will use color from our `theme` (which can be found in `main.dart` file), we can get it from `context`, like this: 
				    ```
				    color: Theme.of(context).accentTextTheme.title.color
				    ```
			    - we also want to add a bit of font style
				    ```
				    fontSize: 42,
				    fontFamily: 'Anton',
				    fontWeight: FontWeight.normal,
				    ```

- now back to `Column` widget 
- `children` property is array , lets add another `Flexible` widget to it.
it will have two properties:
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

now we can import `auth_screen`  in top of `main.dart` file
```
import './screens/auth_screen.dart';
```

### auth button
Lets create the `AuthButton` widget
In `widgets` folder we need to create `autn_button.dart`
It will be `StatelessWidget`

#### what inside widget :
we will be passing parameters to the widget :
`isLoading`,`authMode` and `onSubmit` (just like props in react).
 for that we will need to create properties in `AuthButton` class , and they will be `final` (it's a `StatelessWidget`, once it renders, his properties won't change under any circumstances).
   ```dart
   class AuthButton extends StatelessWidget {
   final bool isLoading;
   ```
 - `authMode` will be in type of  `AuthMode`
 - `onSubmit` will be type of `Function`
	 
 we will create Constructor function with named parameters
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
but then the order of the parameters will be importent, it less convenient while we can enjoy the benefits of named parameters in dart.

```

AuthButton(false, authMode, () =>{}))

VS

AuthButton(isLoading: false, authMode: authMode, onSubmit: () =>{}))
```

Inside build method we will return [`RaisedButton`](https://api.flutter.dev/flutter/material/RaisedButton-class.html) (A material design "raised button").

- `child` propety will have `Text`, it will have to two modes : `login` and `sign up` 

	```dart
	Text(authMode == AuthMode.Login ? 'LOGIN' : 'SIGN UP'),
	```
- `onPress` property will be `onSubmit`, the function we got in our parameters

time for a bit of styling 
```
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
    ),
    padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
    color: Theme.of(context).primaryColor,
    textColor: Theme.of(context)  .primaryTextTheme.button.color,
```
We also need to handle the loading stage 
Therefore we will need to wrapp `RaisedButton` with `if else` segment -
if `isLoading` true then return `CircularProgressIndicator` else return `RaisedButton`

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

### Inputs - Email Input
Lets create the `EmailInput` widget
In `inputs` folder we need to create `email_input.dart`
It will be `StatelessWidget` which gets `onSaved` function

#### what inside widget :
It will return [`TextFormField`](https://api.flutter.dev/flutter/material/TextFormField-class.html) widget (This is a convenience widget that wraps a TextField widget in a FormField).
- `decoretion` property we will use [`InputDecoration`](https://api.flutter.dev/flutter/material/InputDecoration-class.html) 
	- `labelText` will be of 'E-Mail'
- `keyboardType` propetry will be `TextInputType.emailAddress`

we also want to validate the input we get 
- `validator` property will have this code : 
    ```dart
    validator: (value) {
                if (value.isEmpty || !value.contains('@')) {
                    return 'Invalid email!';
                }
                },
    ```
- `onSaved` will pass the value to `onSave` function we got
    ```dart
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

### Inputs - Password Input
Lets create the `PasswordInput` widget
In `inputs` folder we need to create `password_input.dart`
It will be `StatelessWidget` which gets `onSaved` function and `controller` type of [`TextEditingController`](https://api.flutter.dev/flutter/widgets/TextEditingController-class.html)

#### what inside widget :
We will return `TextFormField` widget.
- `decoretion` property we will use [`InputDecoration`](https://api.flutter.dev/flutter/material/InputDecoration-class.html) 
	- `labelText` will be of 'Password'
- `obscureText` will be true
- `controller` will handle the updating 
    ```dart
    obscureText: true,
    controller: controller,
    ```
we also want to validate the input we get 
- `validator` property will have this code : 
    ```dart
    validator: (value) {
        if (value.isEmpty || value.length < 5) {
          return 'Password is too short!';
        }
      },
    ```
- `onSaved` will trigger the `onSave` function we got

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

now we can finnaly build our `AuthCard` widget :raised_hands:

### Auth Card
Lets create the `AuthCard` widget
In `widgets` folder we need to create `auth_card.dart`
It will be `StatefulWidget` 

#### what inside widget :

- make sure to import 
    ```dart
    import 'dart:io';

    import 'package:flutter/material.dart';
    import 'package:provider/provider.dart';
    ```
---
### :exclamation: note  :exclamation: 

[dart:io](https://api.dart.dev/stable/2.7.1/dart-io/dart-io-library.html) is a library that allows you to work with files, directories, sockets, processes, HTTP servers and clients, and more.
[provider](https://pub.dev/packages/provider) (A mixture between dependency injection (DI) and state management, built with widgets for widgets) we will use it as our state managment in our project

---

Under `class AuthCard`  add this line of code: 
```dart
  const AuthCard({
    Key key,
  }) : super(key: key);
```
we need to add `with SingleTickerProviderStateMixin` to `_AuthCardState` so we could to enable useage of `animationController` in `state` part

- lets add some properties for our class to enable useage of our widgets: 
    ```dart
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
<details>
<summary>snippet</summary>
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
</detials>

- for the `onSave` function you will have to pass value and the right key , here is an example : 
```
(value) => _onSaveField('password', value)
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

make sure to import `AuthCard` in `auth_screen`.

now you have everything ready for try login or sign in! :raised_hands:

## Step Two - Home Screen

lets start creating our home screen 

1. we need to create 2 new providers : `item` and `items`
2. we need to refactor our `ItemsOverviewScreen`
3. we need to create new widget `ItemsGrid`

### Items and Item Providers  
Lets create the `Items` and `Item` providers
In `providers` folder we need to create `items.dart` and `item.dart`
they will be `Providers` 

#### what inside providers :

##### Item Provider
`item` provider will represent our item data, whom will be save in our server  
it will be `class` that uses [`ChangeNotifier`](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html) mixin in dart you do it with `with` keyword - 
```dart
class Item with ChangeNotifier
```
it will have those properties:  

```dart
final String id;
final String title;
final String description;
final double price;
final File image;
bool isFavorite;
```  
make sure to import [`foundation.dart`](https://api.flutter.dev/flutter/foundation/foundation-library.html) and import `material.dart` from flutter

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
```
we will need to create a constractor function with `named paramters` 

```dart
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

##### Items Provider
`items` provider will hold all of our `CRUD` (create, read, update, delete) logic against our server

we will be useing `auth` and `user` that we got when we loged in, that way we could have permissions over the each item

copy the code from here :arrow_down:

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

now add this lines of code to `main.dart` file inside `providers` array
```dart
ChangeNotifierProxyProvider<Auth, Items>(
        builder: (ctx, auth, prevpItems) => Items(
            auth.token,
            auth.userId,
            prevpItems == null ? [] : prevpItems.items,
        ),
        ),
```
Don't forget to import import `items.dart`!

###  Refactor Items Overview Screen :muscle:
until now it was just a screen widget that renders loader,
now we will make it show our items

- becasue we now going to work against the server - we will need to handle [`Future`](https://api.flutter.dev/flutter/dart-async/Future-class.html) (async code) , lets start by handling the `init` and `load` stage in `ItemsOverviewScreen`
    
 create `_isInit` and `_isLoading` vars in `_ProductsOverviewScreenState` class , both should be in initial as false
 
- add [`didChangeDependencies`](https://api.flutter.dev/flutter/widgets/AutomaticKeepAliveClientMixin/didChangeDependencies.html) function (Called when a dependency of this State object changes)
It will be handling updates of screen when we will get the items from the server
We will call `fetchAndSetItems` (function we have from `items` provider) to get the products from the server and when it will finish , we will update the state 

```dart
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
Lets refactor `body` in `Scaffold` widget :
```dart
body: _isLoading
      ? Center(
          child: CircularProgressIndicator(),
        )
      : ItemsGrid(),
```

Now we are geting error - it beacuse `ItemsGrid` widget is not exist, we need to create it

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

### Items Grid   
Lets create `ItemsGrid` widget
In `widgets` folder we need to create `items_grid.dart` 
It will be `StatelessWidget` 

#### what inside widget :
Inside build function , we need to get our items from the `Items` provider context

```dart
final items = Provider.of<Items>(context).items;
```

This time we will use [`GridView`](https://api.flutter.dev/flutter/widgets/GridView-class.html) (A scrollable, 2D array of widgets), it will take care of the layout for us.
we will use it in it's builder way : 
 - `itemCount` property will have how many items there are
 - `gridDelegate` property (delegate that controls the layout of the children within the [GridView](https://api.flutter.dev/flutter/widgets/GridView-class.html)) we will pass [`SliverGridDelegateWithFixedCrossAxisCount`](https://api.flutter.dev/flutter/rendering/SliverGridDelegateWithFixedCrossAxisCount-class.html)
- `itemBuilder` property we will need to loop over items and return `ItemWidget`
- `padding` property will get [EdgeInsets](https://api.flutter.dev/flutter/painting/EdgeInsets-class.html).all(10.0)

    ```dart
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
- we are now geting error beacuse `ItemWidget` is not exist -> so we need to create it

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

### Item Widget
Lets create `ItemWidget` widget
In `widgets` folder we need to create `item_widget.dart` 
It will be `StatelessWidget` 

#### what inside widget :
we will need to use `Assets` so we could use Image as placeholder - lets add import in `pubspec.yaml` file 
```yaml
assets:
 - assets/images/wix-logo.jpg
```
In build function ,we will get our item from `Item` provider

```dart
final item = Provider.of<Item>(context, listen: false);
```
we will use now [`ClipRRect`](https://api.flutter.dev/flutter/widgets/ClipRRect-class.html)  (clips its child using a rounded rectangle, similar to `ClipOval`and `ClipPath`)

- `borderRadius` property will be 10
- `child` property will be [`GridTile`](https://api.flutter.dev/flutter/material/GridTile-class.html) which is part of `GridView` list, (we are using `GridView` in our `ItemsWidget` as you know)
it will be covered with [`Hero`](https://api.flutter.dev/flutter/widgets/Hero-class.html) widget, so we will have a nice hero animation (A widget that marks its child as being a candidate for hero animations)
	 - `tag`  propety will be `item.id` , so it will know which widget should get the hero animation, and we will need to add identical tag for the second `Hero` widget the same `tag` (widget where the animation trrigers and the widget where is should haapen)

- `child` property will be [`FadeInImage`](https://api.flutter.dev/flutter/widgets/FadeInImage-class.html) widget (An image that shows a placeholder image while the target image is loading, then fades in the new image when it loads)
- [`placeholder`](https://api.flutter.dev/flutter/widgets/FadeInImage/placeholder.html) proprty will be image from our assets images 
```dart
AssetImage('assets/images/wix-logo.jpg')
```
	- `image` propetry will use [`FileImage`](https://api.flutter.dev/flutter/painting/FileImage-class.html) widget ,it will load the image  as [`File`](https://api.flutter.dev/flutter/dart-io/File-class.html) widget (from `dart:io`)
	- `fit` propetry will be `BoxFit.cover`

-`fotter` will be [`GridTileBar`](https://api.flutter.dev/flutter/material/GridTileBar-class.html)

```dart
GridTileBar(backgroundColor: Colors.black87,
    title: Text(
        item.title,
        textAlign: TextAlign.center,
    ),
)
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

### Item Details Screen
Lets create `ItemDetailScreen` widget
In `screens` folder we need to create `item_detail_screen.dart` 
It will be `StatelessWidget` 
It will show more dutails about the item
   - bigger image
   - details about the item

#### what inside widget :
add route to the file , that way we could approach it

```dart
    static const routeName = '/item-detail';
```
we will need to get the item id somehow so we could be able to show the right item data - we will use `context` for it

when you navigate from `ItemOverviewScreen` (acutally `ItemWidget` inside of it) by clicking on the item , you can pass `arguments` to `ItemDetailScreen`
that way we will be able to use them and get the right item data
we will pass the `item Id`

lets add to `onTap` function in `ItemWidget` which will pass `argumants` - `item.id` inside:

```dart
    Navigator.of(context).pushNamed(
              ItemDetailScreen.routeName,
              arguments: item.id,
            );
```

Now, we will add to `ItemDetailScreen` a call to the `ModalRoute` , so it would be able to get the `itemId` from the arguments, then we'll use it to get the right item from `Items Provider`

```dart
 final itemId = ModalRoute.of(context).settings.arguments as String;
 final loadedItem = Provider.of<Items>(
      context,
      listen: false,
    ).findById(itemId);

``` 
now that we got the infrastructure ready, lets add our ui for screen detail widget 

It  will return `Scaffold`
It will contain our second part of the `Hero` animation 
we will have a new widget - [`CustomScrollView`](https://api.flutter.dev/flutter/widgets/CustomScrollView-class.html) (A ScrollView that creates custom scroll effects using slivers) for a cool scroll
- `slivers` property will contain 
	- [`SliverAppBar`](https://api.flutter.dev/flutter/material/SliverAppBar-class.html) (A material design app bar that integrates with a CustomScrollView).  
		- `expandedHeight` will be 300
		- `pinned` will be true
		- `flexibleSpace` will be [`FlexibleSpaceBar`](https://api.flutter.dev/flutter/material/FlexibleSpaceBar-class.html)
			- `title` will be title of the item
			- `background` will be containing our `Hero` widget 
				- `tag` will be with the same `tag` as in `ItemWidget` (item id)
				- `child` will be `Image.file` - we will get the path to file from `loadedItem.image.path`  and with `fit` property as `BoxFit.cover`
 
	- [`SliverList`](https://api.flutter.dev/flutter/widgets/SliverList-class.html)  (A sliver that places multiple box children in a linear array along the main axis) will contain more details about the item 
		- `delegate` property will be [SilverChildListDelegate](https://api.flutter.dev/flutter/widgets/SliverChildListDelegate-class.html) (A delegate that supplies children for slivers using an explicit list)

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

## Step Three - Add Button and Add Item Screen


###  Refactor Items Overview Screen :muscle:
Lets add add button to our main screen `ItemsOverviewScreen`
 
In `Scaffold` we need to add another property `floatingActionButton`, inside of it we will use [`FloatingActionButton`](https://api.flutter.dev/flutter/material/FloatingActionButton-class.html) widget 
- we will have in `onPressed` property function which will have navigation to our new widget `addItemScreen` widget

```dart
floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AddItemScreen.routeName);
        },
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
```  

### Add Item Screen
Lets create `AddItemScreen` widget
In `screens` folder we need to create `add_item_screen.dart` 
It will be `StatefulWidget` 
It will show more dutails about the item
   - bigger image
   - details about the item

#### what inside widget :

first lets create route to `addItemScreen` screen
```dart
static const routeName = '/add-item';
```
and we need to add this rout to the routs in `main.dart` file

```dart
 AddItemScreen.routeName: (ctx) => AddItemScreen(),
```
Now go to `items.dart` and add the code below , it would be usefull later

```dart
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

Now lets start working on `AddItemScreen` logic and ui
We will have a [`Form`](https://api.flutter.dev/flutter/widgets/Form-class.html) widget for inputs which will be handling the input and its validations

Inside `_AddItemScreenState`: 
we need to create `GlobalKey` for the form state (Global keys uniquely identify elements. Global keys provide access to other objects that are associated with those elements, such as BuildContext. For StatefulWidgets, global keys also provide access to State)
we will have init values for the inputs and also empty `Item` variable

we will use [`TextFormField`](https://api.flutter.dev/flutter/material/TextFormField-class.html) widget for the simple text inputs
for easy navigation between the inputs will use `focusNode` properties so now we need to initate them
Also lets add `isLoading` and `isInit` variables

```dart
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
Now we can start working on the ui, we will return `Scaffold` widget (it will be similar to our other `Scaffold` widgets)

```dart
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

Now we can start adding the inputs widgets 

`Form` lets us use `onSubmit` function for all the inputs inside of it, therefore we will have in each `TextFieldInput` widget `onSave` function to handle it self when it got submitted

- each input will get its own `initValue` property from `_initValues` variable
- each input will have `decoration` property with his title 
- `onFieldSubmitted` property will be moving focus between inputs after submiting each one
- `validator` property will get input value and check it with our custome validation rules  

```dart
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

Now create also `price` and `description` textFields by yourself 

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

### Image Input
Lets create `ImageInput` widget
In `inputs` folder we need to create `image_input.dart` 
It will be `Stateful` 
it will get `onSelectImage` function from `AddItemScreen` so it would be avialable in the form and will pass back image file
we will use [`image_picker`](https://pub.dev/packages/image_picker) package

#### what inside widget :

Lets create `takePicture` function , which will take picture with phone camera , and  `storedImage` variable

```dart        
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

Now add this code for the input ui 
`onPressed` will trriger `_takePicture` function , and then will update `AddItemScreen` form

```dart
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
    
back to the form , lets add `ImageInput` under the others inputs in `ListView` children list
```dart
Container(
                  width: 100,
                  height: 100,
                  margin: EdgeInsets.only(top: 8, right: 10),
                  child: ImageInput(_selectImage),
                ),
```

- we will pass as argumanet `_selectImage` function
```dart
void  _selectImage(File pickedImage) {

_pickedImage = pickedImage;

}
```
now we will create `_saveForm` function , it will validate our inputs and then will add new item
- it will show loader while we are wating for response
- in case of error it will show [`AlertDialog`](https://api.flutter.dev/flutter/material/AlertDialog-class.html)
- after it will finish all steps, it will close `AddItemScreen` 
	- it will use ```Navigator.of(context).pop())``` to close screen after add new item will finish

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

Now all left to do is to [`dispose`](https://api.flutter.dev/flutter/animation/AnimationEagerListenerMixin/dispose.html) all inputs elements with `focusNode` in `dispose` time (Called when this object is removed from the tree permanently) 

```dart
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

## Step Four - App Drawer

We are starting to have lots of screens, we should make navigation between them easy 
Lets make navigation menu which would be `App Drawer`

For now it will have buttons for `Logout` and `Home` navigation

### Image Input
Lets create `AppDrawer` widget
In `widgets` folder we need to create `app_drawer.dart` 
It will be `StatelessWidget` 
It will return [`Drawer`](https://api.flutter.dev/flutter/material/Drawer-class.html) widget (A material design panel that slides in horizontally from the edge of a Scaffold to show navigation links in an application)

#### what inside widget :
inside `Drawer` we will return `Column` widget with some widgets:
- `AppBar` with `title` and inside it  (An app bar consists of a toolbar and potentially other widgets, such as a TabBar and a FlexibleSpaceBar. App bars typically expose one or more common actions with IconButtons which are optionally followed by a PopupMenuButton for less common operations (sometimes called the "overflow menu"))

	```dart
	AppBar(
	        title: Text('Flutter Wix Workshop'),
	        automaticallyImplyLeading: false,
	    ),
	```

- [`Divider`](https://api.flutter.dev/flutter/material/Divider-class.html) (A thin horizontal line, with padding on either side)
- [`ListTile`](https://api.flutter.dev/flutter/material/ListTile-class.html) (A single fixed-height row that typically contains some text as well as a leading or trailing icon)
        it will contain the `Icon` ,`Text` and `onTap` properties
        
	```dart
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
we will make two sets of `Divider` + `ListTile` for `Logout` and `Home`

 try to create one for `Home` with home icon. `onTap` will navigate to `ItemsOvwerviewScreen` (it will `pushReplacementNamed` and not just `push` the rout)

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

Now we can start using our new `AppDrawer`
- In `itemsOverViewScreen` widget add our `appDrawer` widget inside `drawer` property of `Scafolled`

```dart
drawer: AppDrawer(),
```

## Step Five - Mangeing Items

so we can add new Item already , but what about delete it ? or maybe edit it
we need a place to mange our items

### Mange Items Screen
Lets create `MangeItemsScreen` widget
In `screens` folder we need to create `mange_items_screen.dart` 
It will be `StatelessWidget` 
In this page we will show **only** items which the logged in user created
we will pass `filterByUser` true to `fetchAndSetItems` function in the `items provider`

#### what inside widget :

First lets add route to it just like before

```dart
static const routeName = '/manage-items';
```

We need also to add the rout to `main.dart` file 

```dart
ManageItemsScreen.routeName: (ctx) => ManageItemsScreen(),
``` 


We will use [`FutureBuilder`](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html) widget (Widget that builds itself based on the latest snapshot of interaction with a Future)

Lets create `_refreshItems` function and pass it to `FutureBuilder` `future` property ,it will be triggered eachwe refresh the screen

```dart
  Future<void> _refreshItems(BuildContext context) async {
    await Provider.of<Items>(context, listen: false).fetchAndSetItems(true);
  }
```

We will return `Scaffold` widget 
Inside it will have `AppBar` 
- `actions` property will contain [`IconButton`](https://api.flutter.dev/flutter/material/IconButton-class.html) with `add` icon and `onPressed` function which will navigate us to `AddItemScreen`
- `drawer` property will be with our `appDrawer` widget we created before 

```dart
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

- `body` property  will have `FutureBuilder` widget which will contain two properties : `future` and `builder`
    - `future` property will contain `_refreshItems(context)`
    - `builder` property will get called first when the widget is renderd (we will show `CircularProgressIndicator` widget for it) , then when the future will finish and we will get response, `FutureBuilder` will handle it, and we will get to show the items.

```dart
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

We are missing a widget for the represent `items` data we have , so lets create one

### Mange Item View
Lets create `ManageItemView` widget
In `widgets` folder we need to create `manage_item_view.dart` 
It will be `StatelessWidget` 
It will get `id`, `title`, and `image` as class properties

```dart
  final String id;
  final String title;
  final File image;

  ManageItemView(this.id, this.title, this.image);
``` 

#### what inside widget :

It will return [`ListTile`](https://api.flutter.dev/flutter/material/ListTile-class.html) widget (A single fixed-height row that typically contains some text as well as a leading or trailing icon)
it will contain `title`, `leading` and `trailing` properties
 - `title` property will be `Text` widget of the title we got 
 - `leading` property will be [`CircleAvatar`](https://api.flutter.dev/flutter/material/CircleAvatar-class.html) widget with `backgroundImage` of the Image we got
 - `trailing` property will return `Container` widget , for now it will return empty `Row` widget

```dart
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

#### Back to `MangeItemsScreen`
Lets fill up the code that missing in `MangeItemsScreen` in the `itemBuilder childern` 

```dart
 ManageItemView(
        itemsData.items[i].id,
        itemsData.items[i].title,
        itemsData.items[i].image,
    ),
``` 

#### Back to `AppDrawer`
Lets add button for our manage page in the `AppDrawer`, under `home` button we will add `Divider` and `ListTile` with 'Mange Items' text

```dart
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

### Delete Item

Lets start with adding this code to `items.dart` which will remove items from our server

```dart
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

Now lets add button in `ManageItemView` widget, which will remove the item when it got clicked
- Under `trailing -> children widgets` , we will add `IconButton` widget  who will be with icon `delete`
    - `onPressed` will call our new function in `Items` provider , it will pass `id` of item that will be removed
    - `listen: false` will get value once and ignore updates (we don't need more)
    - in case of error we will show [`snackBar`](https://api.flutter.dev/flutter/material/SnackBar-class.html)
        - we need to get Scaffold from the context for that (under widget `build` function we will add it)

			```dart
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

# Bonus Part: Like Button

## Step Six - Like Button

we want to have new action - like an item
It will be spread in couple of widgets

### Like Button

Lets add like button on the item in our home screen

first lets add the function we need in our `Item` provider (this time not `Items` provider)
It will update item `isFavorite` staus in server for us

```dart
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

Lets add new button for it in `ItemWidget`
we need first to get `authData` from `AuthProvider` 
   - we need to add this line of code under `build` function
		```dart
		final authData = Provider.of<Auth>(context, listen: false);
		```
		
Lets add `leading` property inside our footer [`GridTileBar`](https://api.flutter.dev/flutter/material/GridTileBar-class.html) widget 
It will be `Consumer` widget , and it will listen to `Item` provider
 - `builder` property will hold inside `IconButton` which will show `favorite` icaon or `favorite_border` (depens if its liked or not)
- `onPressed` property will trriger `toggleFavoriteStatus` function 
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

Lets add popup menu to select if we want to show only favorites items
In `ItemsOverviewScreen` in `AppBar`  widget, we will add `actions` property 
- we will use [`PopupMenuButton`](https://api.flutter.dev/flutter/material/PopupMenuButton-class.html) widget (Displays a menu when pressed and calls onSelected when the menu is dismissed because an item was selected. The value passed to onSelected is the value of the selected menu item)

    - `onSelect` property will get selected value and will check if `_showOnlyFavorites` should be true or false
    - `icon` property will be `Icons.more_vert`


- we need to add `enum FilterOptions` ,lets add it on top of our class 
    ```dart
    enum FilterOptions { Favorites, All }
    ```
    
    - `itemBuilder` property will be array of [`PopupMenuItem`](https://api.flutter.dev/flutter/material/PopupMenuItem-class.html) widget
        - one will be `Only Favorites` with value of `FilterOptions.Favorites` 
        - another one will be `Show All` with value of `FilterOptions.All`

- we need to add to call to`Items` provider 
```dart
  List<Item> get favoritesItems {
    return _items.where((productItem) => productItem.isFavorite).toList();
  }
```

Now lets pass `_showFavorites` to `ItemsGrid`

#### refactor Items Grid

Inside `ItemsGrid` we will add `showOnlyFavorites` property to the class

```dart
final bool showOnlyFavorites;

ItemsGrid(this.showOnlyFavorites);
```

We just need to get the right product according to the `showFavorites` property 

```dart
final productsData = Provider.of<Products>(context);
    final prodcuts =
        showOnlyFavorites ? productsData.favoritesItems : productsData.items;
```
now lets just to update `fetchAndSetItems` in `Items` provider

```dart
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