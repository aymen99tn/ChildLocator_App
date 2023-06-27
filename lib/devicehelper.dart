import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



Future<Map<String, String>> getDeviceDetails(BuildContext context) async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String? productName;
  String? token;
  if (Theme.of(context).platform == TargetPlatform.android) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    productName = androidInfo.product;
    }
   else if (Theme.of(context).platform == TargetPlatform.iOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    productName = iosInfo.utsname.machine;
  }
  token = await FirebaseMessaging.instance.getToken();

  return {
    'productName': productName ?? 'unknown',
    'token': token ?? 'unknown',
  };
}



Future<void> storeDeviceDetails(Map<String, String> deviceDetails) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference devicesRef = firestore.collection('devices');
  await devicesRef.doc(deviceDetails['productName']).set({
    'token': deviceDetails['token'],
    'timestamp': FieldValue.serverTimestamp(),
  });
}

Future<String?> getChildDeviceToken(String productName) async {
  DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('devices').doc(productName).get();
  return snapshot['token'];
}

Future<String?> getChildDeviceNumber(String productName) async {
  DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('devices').doc(productName).get();
  return snapshot['phoneNumber'];
}

Future<Position?> _getLocation() async {
  LocationPermission permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }
  return await Geolocator.getCurrentPosition();
  }

  Future<void> onMessageReceived(Map<String, dynamic> message) async {
  print('onMessage: $message');

  // Get the parent device ID from the FCM message data
  final parentDeviceId = message["parent_device_id"];
  final parentToken=await getChildDeviceToken(parentDeviceId);
  print('Parent device token: $parentToken');

  // Get the current location of the device
  final position = await _getLocation();
  final latitude = position?.latitude.toString();
  final longitude = position?.longitude.toString();
  print('Current location: $latitude, $longitude');

  // Construct the FCM message to send the location back to the parent
  final body = {
    "to": parentToken,
    "notification": {
      "title": "Child location",
      "body": "Child location: $latitude, $longitude",
    },
    "data": {
      "type": "location_response",
      "latitude": latitude,
      "longitude": longitude,
    },
  };

  print('FCM message body: $body');
  
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
}


