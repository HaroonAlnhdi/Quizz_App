import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizDegrees extends StatefulWidget {
  const QuizDegrees({super.key});

  @override
  State<QuizDegrees> createState() => _QuizDegreesState();
}

class _QuizDegreesState extends State<QuizDegrees> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> _getUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      return userSnapshot.data() as Map<String, dynamic>? ?? {};
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> _getUserQuizzes() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    QuerySnapshot answerSnapshot = await _firestore
        .collection('Answers')
        .where('user', isEqualTo: user.uid)
        .get();

    return Future.wait(answerSnapshot.docs.map((doc) async {
      final data = doc.data() as Map<String, dynamic>;
      final examSnapshot = await _firestore
          .collection('Exams')
          .doc(data['exam'])
          .get();
      final examData = examSnapshot.data() as Map<String, dynamic>;
      return {
        'quizTitle': examData['title'],
        'className': examData['class'],
        'grade': data['grade'],
        'totalPoint': data['totalPoint'],
      };
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Quiz Degrees',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getUserQuizzes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No quiz degrees found.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          } else {
            final quizzes = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quiz: ${quiz['quizTitle']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Class: ${quiz['className']}'),
                        const SizedBox(height: 8),
                        Text('Grade: ${quiz['grade']} / ${quiz['totalPoint']}'),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}