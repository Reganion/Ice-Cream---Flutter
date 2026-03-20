import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ice_cream/services/fcm_push_service.dart';
import 'client/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FcmPushService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Color(0xFFB3D7FF),
          selectionHandleColor: Colors.black,
        ),
      ),
      home: const LandingPage(),
    );
  }
}
