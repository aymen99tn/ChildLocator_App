import 'package:flutter/material.dart';
import 'package:pfa_app/authscreen.dart';
import 'package:pfa_app/devicehelper.dart'; // Import the devicehelper.dart file
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _phoneNumberController = TextEditingController();
  bool _phoneNumberSaved = false;

  void onAppStart(BuildContext context) async {
    Map<String, String> deviceDetails = await getDeviceDetails(context);
    await storeDeviceDetails(deviceDetails);
  }

  void navigateToAuthScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen()),
    );
  }

   void _storePhoneNumber(String phoneNumber) async {
    Map<String, String> deviceDetails = await getDeviceDetails(context);
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference devicesRef = firestore.collection('devices');
    await devicesRef.doc(deviceDetails['productName']).update({
      'phoneNumber': '216'+phoneNumber,
    });
    setState(() {
        _phoneNumberSaved = true;
      });
  }
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    onAppStart(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      onAppStart(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Home Screen'),
            const SizedBox(height: 20),
            if (!_phoneNumberSaved)
              Column(
                children: [
                  const Text('Please enter your phone number:'),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _storePhoneNumber(_phoneNumberController.text),
                    child: const Text('Save Phone Number'),
                  ),
                ],
              ),
            if (_phoneNumberSaved)
              const Text('Phone number saved!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: navigateToAuthScreen,
              child: const Text('Authenticate'),
            ),
          ],
        ),
      ),
    );
  }
}

