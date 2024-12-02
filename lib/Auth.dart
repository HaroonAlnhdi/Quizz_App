
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:quiz_app/screens/LoginView.dart';
import 'package:quiz_app/screens/admin/HomeViewAdmin.dart';


class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
         builder:((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            return const HomeViewAdmin();
          } else if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          } else {
            return const LoginView();
          }
        }

         
         
         ),
    )
    );
  }

}