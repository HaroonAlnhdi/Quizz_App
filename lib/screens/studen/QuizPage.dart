
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class QuizPage extends StatelessWidget {

  const QuizPage({super.key});

Future<List<Map<String, dynamic>>> getExam() async {
  // Fetch the exam document
  var examSnapshot = await FirebaseFirestore.instance
      .collection('Exams')
      .doc('GW9wp6qWKUvI8fad3mhr')
      .get();

  // Ensure the document exists and contains a 'questions' field
  if (!examSnapshot.exists || examSnapshot.data()?['questions'] == null) {
    throw Exception('Exam not found or missing questions field.');
  }

  var questions = examSnapshot.data()?['questions'] as List<dynamic>;

  // Fetch all questions using Future.wait
  var questionSnapshots = await Future.wait(
    questions.map((questionId) async {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('Questions')
          .where('id', isEqualTo: questionId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      } else {
        throw Exception('Question not found for id: $questionId');
      }
    }).toList(),
  );

  return questionSnapshots;
}




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
        future: getExam(),
        builder: (context,snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                "No quizzes available.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          var doc = snapshot.data!;

          return Scaffold(
            body: ListView(
            children: [
              for (var question in doc)
                Text(question['text']),

            ],
            ),
          );
        } 
      ),
  
    );

  }

}
