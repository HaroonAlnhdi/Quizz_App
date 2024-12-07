import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
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

  int _currentIndex = 0;

  void _goToNextQuestion(int totalQuestions) {
    if (_currentIndex < totalQuestions - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _goToPreviousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text('Quiz Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getExam(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No quizzes available.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          var questions = snapshot.data!;
          var currentQuestion = questions[_currentIndex];

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      currentQuestion['text'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _goToPreviousQuestion,
                    icon: const Icon(Icons.arrow_left),
                    iconSize: 40,
                    color: _currentIndex > 0 ? Colors.blue : Colors.white,
                  ),
                  IconButton(
                    onPressed: () => _goToNextQuestion(questions.length),
                    icon: const Icon(Icons.arrow_right),
                    iconSize: 40,
                    color: _currentIndex < questions.length - 1
                        ? Colors.blue
                        : Colors.white,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
