import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pfa_app/homescreen.dart';
import 'package:pfa_app/devicehelper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pfa_app/parentscreen.dart';
import 'package:pfa_app/notif.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  configureFirebaseListeners(messaging);

  runApp(MyApp());
}


Future<void> backgroundMessageHandler(RemoteMessage message) async {
  print("Background message received: $message");

  if (message.data['type'] == 'location_request') {
    // Call the function to handle the location request
    onMessageReceived(message.data);
  }
}

void configureFirebaseListeners(FirebaseMessaging messaging) {
  // When a notification is received while the app is in the foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("onMessage: $message");

    if (message.data['type'] == 'location_request') {
      // Call onMessageReceived function with the message data
      // Make sure to import the file containing the onMessageReceived function
      onMessageReceived(message.data);
    }
  });

  // When a notification is received while the app is in the background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("onMessageOpenedApp: $message");

    if (message.data['type'] == 'location_request') {
      // Call onMessageReceived function with the message data
      // Make sure to import the file containing the onMessageReceived function
      onMessageReceived(message.data);
    }
  });

  // When the user clicks on a notification
  messaging.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print("getInitialMessage: $message");

      if (message.data['type'] == 'location_request') {
        // Call onMessageReceived function with the message data
        // Make sure to import the file containing the onMessageReceived function
        onMessageReceived(message.data);
      }
    }
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Child Locator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}
