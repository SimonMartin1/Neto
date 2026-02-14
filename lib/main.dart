import 'package:flutter/material.dart';
import 'package:neto/core/app_theme.dart'; 
import 'package:neto/screens/main_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neto',
      // debugShowCheckedModeBanner: false,
      
      theme: AppTheme.lightTheme, 
      
      home: const MainScreen(),
    );
  }
}
