import 'package:flutter/material.dart';
import 'calcualtor_screen.dart';

void main() {
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
