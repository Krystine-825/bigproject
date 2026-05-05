import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'screens/auth/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart';  
import 'package:firebase_app_check/firebase_app_check.dart';
import 'data/services/fcm_service.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

   await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity, 
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
  );
   await FcmService.initBackgroundHandler();
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduExam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007BFF)),
        fontFamily: 'Lexend',
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}
