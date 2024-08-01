import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_page.dart';
import 'location_page.dart';
import 'drone_detail.dart';
import 'tracking_page.dart';
import 'qr_scan_page.dart';
import 'return_page.dart';
import 'register_page.dart';
import 'login_page.dart';
import 'payment_page.dart';
import 'firebase_options.dart'; // Firebase options file

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter binding
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/location': (context) => LocationPage(),
        /*
        '/droneSelection': (context) => DroneSelectionPage(),
        '/payment': (context) => PaymentPage(),
        '/tracking': (context) => TrackingPage(),
         */

        '/qrScan': (context) => QRScanPage(),
        '/return': (context) => ReturnPage(),
      },
    );
  }
}
