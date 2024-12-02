import 'package:flutter/material.dart';
import 'package:quiz_app/screens/LoginView.dart';
import 'package:quiz_app/screens/SignupView.dart';
import 'package:quiz_app/screens/splashView.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
     return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashView(),
        '/login': (context) => const LoginView(),
        '/signup': (context) => const SignupView(),
      },
    );
  }
}
