import 'dart:async';

import 'package:flutter/material.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    Timer(const Duration( seconds: 2 ), () 
    {
      Navigator.pushReplacementNamed(context, '/login',);
    });
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image(image: AssetImage('assets/qq.jpg')),
      ),
    );
  }
}