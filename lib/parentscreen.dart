import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pfa_app/authservice.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';  
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:pfa_app/devicehelper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pfa_app/notif.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();


class ParentScreen extends StatefulWidget {
  @override
  _ParentScreenState createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();
  String _selectedDeviceId = '';

@override
void initState() {
  super.initState();

  // ... (other initialization code)

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Message received in the foreground: ${message.data}');
    String? title = message.notification?.title;
    String? body = message.notification?.body;

    if (title != null && body != null) {
      // You'll need to pass the current BuildContext to this method
      showInAppNotification(context, title, body);
    }
  });
}
void showInAppNotification(BuildContext context, String title, String body) {
  OverlayEntry overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: InAppNotification(title: title, message: body),
    ),
  );

  Overlay.of(context).insert(overlayEntry);

  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}

  Stream<QuerySnapshot> getDevices() {
    return _db.collection('devices').snapshots();
  }

  void onDeviceSelected(String deviceId) {
    setState(() {
      _selectedDeviceId = deviceId;
      });
  }
 
Future<void> sendLocationRequest(String childUserId) async {
  // Get the FCM token of the target child device
  String? childDeviceToken = await getChildDeviceToken(_selectedDeviceId);
  Map<String, String> deviceDetails = await getDeviceDetails(context);
  String? currentdevice = deviceDetails['productName'];

  if (childDeviceToken != null) {
    print('Child device token: $childDeviceToken');
    // Prepare the FCM message
    final body = {
      "to": childDeviceToken,
      "notification": {
        "title": "Location Request",
        "body": "Parent requested your location.",
      },
      "data": {
        "type": "location_request",
        "parent_device_id": currentdevice,
      },
    };

    // Send the FCM message
    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "key=AAAAeyyOQ58:APA91bEazvYxk2khTLgEffjfQgz0N1jc7WpuMKGO4rg8nLqvxj-mq17SAmd0YTbMRun-iaThE-Kn6yOi_dPrGTPMN0gUcwW5HMISdHKHjD9K5fIE42I1PnwICK34PcEs1Fj1qurrmHK_",
      },
      body: json.encode(body),
      
    );
       print('FCM response status code: ${response.statusCode}');
      print('FCM response body: ${response.body}');

    if (response.statusCode == 200) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Message sent successfully.')),
      );
    } else {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Failed to send message: ${response.body}')),
      );
    }
  } else {
    _scaffoldMessengerKey.currentState?.showSnackBar( // Change this line
      const SnackBar(content: Text('Failed to send message')),
    );
  }
}


Future<void> sendLocationRequestSMS(String childUserId) async {
  // Get the phone number and FCM token of the target child device
  String? childDeviceToken = await getChildDeviceToken(_selectedDeviceId);
  String? childPhoneNumber = await getChildDeviceNumber(_selectedDeviceId);

  if (childDeviceToken != null && childPhoneNumber != null) {
    print('Child device token: $childDeviceToken');
    print('Child phone number: $childPhoneNumber');

    // Compose the SMS message
    String message = "Parent requested your location. Please share your location.";
    List<String> recipents = [childPhoneNumber];

    // Send the SMS message
    try {
      await sendSMS(message: message, recipients: recipents);
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Message sent successfully.')),
      );
    } catch (error) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Failed to send message: ${error.toString()}')),
      );
    }
  } else {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Failed to send message')),
    );
  }
}



  Future<void> _showDeviceListDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a device'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: getDevices(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot device = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(device.id),
                      trailing: _selectedDeviceId == device.id
                         ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        onDeviceSelected(device.id);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }



  @override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async => false,
    child: ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(title: const Text('Parent Screen')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Request child location:'),
              ElevatedButton(
                onPressed: () => sendLocationRequestSMS(_selectedDeviceId), // Update this line
                child: const Text('Send location request'),
              ),
              const SizedBox(height: 20), // Add some spacing between the buttons
              ElevatedButton(
                onPressed: _showDeviceListDialog,
                child: const Text('Show devices'),
              ),
              const SizedBox(height: 20), // Add some spacing between the buttons
              ElevatedButton(
                onPressed: () async {
                  await _auth.signOut();
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}