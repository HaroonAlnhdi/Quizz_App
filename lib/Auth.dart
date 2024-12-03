import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:quiz_app/screens/LoginView.dart';
import 'package:quiz_app/screens/admin/HomeViewAdmin.dart';
import 'package:quiz_app/screens/studen/HomeViewStudent.dart';


class Auth extends StatelessWidget {
  const Auth({super.key});

  Future<String?> _getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc['role'];
      } else {
        return null; 
      }
    } catch (e) {
      return null; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            final User user = snapshot.data!;
            
            return FutureBuilder<String?>(
              future: _getUserRole(user.uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (roleSnapshot.hasData) {
                  final role = roleSnapshot.data;
                  if (role == 'admin') {
                    return const HomeViewAdmin();
                  } else if (role == 'student') {
                    return const HomeViewStudent();
                  } else {
                    return const Center(child: Text('Unknown role'));
                  }
                } else {
                  return const Center(child: Text('Error retrieving role'));
                }
              },
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          } else {
            return const LoginView();
          }
        },
      ),
    );
  }
}
