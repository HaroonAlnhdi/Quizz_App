import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Routes
import 'package:quiz_app/screens/LoginView.dart';
import 'package:quiz_app/screens/SignupView.dart';
import 'package:quiz_app/screens/splashView.dart';
import 'package:quiz_app/screens/admin/HomeViewAdmin.dart';
import 'package:quiz_app/Auth.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        '/auth': (context) => const Auth(),
        '/login': (context) => const LoginView(),
        '/signup': (context) => const SignupView(),
        '/homeAdmin': (context) => const HomeViewAdmin(),
      },
    );
  }
}
