import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeViewAdmin extends StatefulWidget {
  const HomeViewAdmin({super.key});

  @override
  State<HomeViewAdmin> createState() => _HomeViewAdminState();
}

class _HomeViewAdminState extends State<HomeViewAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home View Admin'),
        backgroundColor: Color(0xFF7826B5),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
             FirebaseAuth.instance.signOut();
            },
          ),

        ],
      ),
      
      body: Center(
        child: Text('Admin'),
      ),
    );

  }
}