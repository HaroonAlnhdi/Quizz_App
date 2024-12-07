
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class QuizPage extends StatelessWidget {

  const QuizPage({super.key});



  @override

  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Colors.purple,
        title: Text('Quiz Page'),
          actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
             FirebaseAuth.instance.signOut();
            },
          ),

        ],
      ),
      body: 
    FutureBuilder(
      future: FirebaseFirestore.instance.collection('Exams').doc('GW9wp6qWKUvI8fad3mhr').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('exam is not available'));
        }
        var exam = snapshot.data!;
        return ListTile(
          title: Text(exam['title']),
          subtitle: Text(exam['description']),
          onTap: () {
        // Handle exam tap
          },
        );
      },
    )
    );

  }

}
