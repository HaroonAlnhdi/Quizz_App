import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';


import 'package:quiz_app/firebase_options.dart';

// Routes
import 'package:quiz_app/screens/LoginView.dart';
import 'package:quiz_app/screens/SignupView.dart';
import 'package:quiz_app/screens/admin/QuizsListPage.dart';
import 'package:quiz_app/screens/studen/QuizPage.dart'; // Add this line
import 'package:quiz_app/screens/splashView.dart';
import 'package:quiz_app/screens/admin/HomeViewAdmin.dart';
import 'package:quiz_app/Auth.dart';
//student

import 'package:quiz_app/screens/studen/HomeViewStudent.dart';
import 'package:quiz_app/screens/admin/CreateClass.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(

  options: DefaultFirebaseOptions.currentPlatform,

   );

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
        '/homeStudent': (context) => const HomeViewStudent(),
        '/QuizsListPage': (context) => const QuizsListPage(),
        '/quizPage': (context) => QuizPage(),
      },
    );
  }
}
