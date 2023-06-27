import 'package:flutter/material.dart';
import 'package:pfa_app/authservice.dart';
import 'package:pfa_app/parentscreen.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final AuthService _auth = AuthService();
  String email = '';
  String password = '';

  void navigateToParentScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ParentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(title: const Text('Auth Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  email = value;
                });
              },
              decoration: const InputDecoration(hintText: 'Email'),
            ),
            TextField(
              onChanged: (value) {
                setState(() {
                  password = value;
                });
              },
              decoration: const InputDecoration(hintText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () async {
                dynamic result =
                    await _auth.signInWithEmailAndPassword(email, password);
                if (result == null) {
                  print('Error signing in');
                  const snackBar = SnackBar(
                    content: Text('Authentication failed'),
                    duration: Duration(seconds: 10),
                  );
                  _scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
                } else {
                  print(result);
                  navigateToParentScreen();
                }
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
