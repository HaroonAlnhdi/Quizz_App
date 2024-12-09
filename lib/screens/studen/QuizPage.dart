import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizPage extends StatefulWidget {
  final String ExamId;

  @override
  _QuizPageState createState() => _QuizPageState();
  const QuizPage({Key? key, required this.ExamId}) : super(key: key);
}

class _QuizPageState extends State<QuizPage> {
  late Future<List<Map<String, dynamic>>> _examFuture;
  final Map<String, dynamic> _answers = {};
  int _currentIndex = 0;
  late DateTime _endTime;
  late Timer _timer;
  String _timeRemaining = "00:00";

  @override
  void initState() {
    super.initState();
    _examFuture = getExam();
    initializeTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> initializeTimer() async {
    final examData = await FirebaseFirestore.instance
        .collection('Exams')
        .doc(widget.ExamId)
        .get();
    final startTime = examData['startTime'] as String;
    final endTime = examData['endTime'] as String;

    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(startTime.split(":")[0]),
      int.parse(startTime.split(":")[1]),
    );
    _endTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endTime.split(":")[0]),
      int.parse(endTime.split(":")[1]),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _endTime.difference(DateTime.now());
      if (remaining.isNegative) {
        _timer.cancel();
        submitForReal();
      } else {
        setState(() {
          _timeRemaining =
              "${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}";
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getExam() async {
    final examSnapshot = await FirebaseFirestore.instance
        .collection('Exams')
        .doc(widget.ExamId)
        .get();
    if (!examSnapshot.exists || examSnapshot.data()?['questions'] == null) {
      throw Exception('Exam not found or missing questions field.');
    }
    final questions = examSnapshot.data()?['questions'] as List<dynamic>;
    return Future.wait(
      questions.map((questionId) async {
        final querySnapshot = await FirebaseFirestore.instance
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
  }


  void submitForReal() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not found.');
  }
  final examSnapshot = await FirebaseFirestore.instance
      .collection('Exams')
      .doc(widget.ExamId)
      .get();
  final questions = await _examFuture;
  final grade = calculateGrade(questions);
 
  int totalPoint = questions.fold(0, (sum, question) => sum + (question['points'] as int));
  final submission = {
    'user': user.uid,
    'timestamp': FieldValue.serverTimestamp(),
    'exam': widget.ExamId,
    'grade': grade,
    'totalPoint': totalPoint,
    'answers': _answers,

  };

  await FirebaseFirestore.instance.collection('Answers').add(submission);

  _showSuccessDialog(context);
}

void _showSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Submission Successful"),
        content: const Text("Your quiz has been submitted successfully."),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); 
              Navigator.of(context).pushReplacementNamed('/homeStudent'); 
            },
            icon: const Icon(Icons.check, color: Colors.green),
            label: const Text("OK"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
          ),
        ],
      );
    },
  );
}

  double calculateGrade(List<Map<String, dynamic>> questions) {
    var correct = 0;
    for (var question in questions) {
      if (question['type'] == 'MCQ' || question['type'] == 'True/False') {
        final correctOption = question['correctOption'];
        if (_answers[question['id']] == correctOption) {
          correct += question['points'] as int? ?? 0;
        }
      }
    }
    return correct.toDouble();
  }

void _showSubmitConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Submit Quiz"),
        content: const Text("Are you sure you want to submit the quiz?"),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); 
            },
            icon: const Icon(Icons.cancel, color: Colors.red),
            label: const Text("Cancel"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); 
              submitForReal(); 
            },
            icon: const Icon(Icons.check, color: Colors.green),
            label: const Text("Submit"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
          ),
        ],
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.purple,
        title: Image.asset('assets/logo.png', height: 50),
        actions: [
        Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Add margin
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: Colors.white), // Add icon
                  const SizedBox(width: 8), // Add space between icon and text
                  Text(
                    _timeRemaining,
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _examFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No quizzes available."));
          }
          final questions = snapshot.data!;
          final currentQuestion = questions[_currentIndex];

          return Container(
            margin: EdgeInsets.all(1),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Question ${_currentIndex + 1} of ${questions.length}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          currentQuestion['text'],
                          style: const TextStyle(fontSize: 20 , fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        if (currentQuestion['type'] == 'True/False') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _answers[currentQuestion['id']] = 'True';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _answers[currentQuestion['id']] == 'True'
                                      ? Colors.green
                                      : Colors.white,
                                ),
                                child: const Text('True'),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _answers[currentQuestion['id']] = 'False';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _answers[currentQuestion['id']] == 'False'
                                      ? Colors.red
                                      :  Colors.white,
                                ),
                                child: const Text('False'),
                              ),
                            ],
                          ),
                        ] else if (currentQuestion['type'] == 'MCQ') ...[
                          Wrap(
                            spacing: 10,
                            children: (currentQuestion['options'] ?? [])
                                .map<Widget>(
                                  (option) => ChoiceChip(
                                    label: Text(option),
                                    selected: _answers[currentQuestion['id']] == option,
                                    onSelected: (selected) {
                                      setState(() {
                                        _answers[currentQuestion['id']] =
                                            selected ? option : null;
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ] else if (currentQuestion['type'] == 'Text') ...[
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _answers[currentQuestion['id']] = value;
                              });
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter your answer',
                            ),
                          ),
                        ] else ...[
                          Text('Unknown question type: ${currentQuestion['type']}'),
                        ],
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back , color: Colors.purple , size: 50),
                      onPressed: _currentIndex > 0
                          ? () => setState(() => _currentIndex--)
                          : null,
                    ),
                    if (_currentIndex == questions.length - 1)
                    ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                          onPressed: () {
                            _showSubmitConfirmationDialog(context);
                          },
                          child: const Text("Submit" , style: TextStyle(fontSize: 20 , color: Colors.white)),
                        ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward , color: Colors.purple , size: 50),
                      onPressed: _currentIndex < questions.length - 1
                          ? () => setState(() => _currentIndex++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


