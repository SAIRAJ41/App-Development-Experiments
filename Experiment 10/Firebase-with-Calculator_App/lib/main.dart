import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'calcualtor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using default options from google-services.json
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CalculatorScreen(),
    );
  }
}
