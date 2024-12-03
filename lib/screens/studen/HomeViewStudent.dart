import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeViewStudent extends StatefulWidget {
  const HomeViewStudent({super.key});

  @override
  State<HomeViewStudent> createState() => _HomeViewStudentState();
}

class _HomeViewStudentState extends State<HomeViewStudent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        backgroundColor: Colors.purple,
        title: Text('Home View Student'),
          actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
             FirebaseAuth.instance.signOut();
            },
          ),

        ],
      ),
      body: const Center(
        child: Text('Welcome to Home View Student!'),
        
      ),
    );
  }
}