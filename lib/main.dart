import 'package:flutter/material.dart';
import 'screens/auth/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart';  
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

   await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, 
    //appleProvider: AppleProvider.debug,
  );
  
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
