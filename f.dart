import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class QuizPage extends StatefulWidget {
  final String examId;

  const QuizPage({Key? key, required this.examId}) : super(key: key);

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late Future<List<Map<String, dynamic>>> _examFuture;
  late Timer _timer;
  Duration _remainingTime = Duration.zero;
  bool _isTimeOver = false;

  final TextEditingController _controller = TextEditingController();
  final Map<String, dynamic> _answers = {};
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _examFuture = getExam();
    _initializeTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeTimer() async {
    final exam = await FirebaseFirestore.instance
        .collection('Exams')
        .doc(widget.examId)
        .get();

    if (exam.exists) {
      final data = exam.data()!;
      final startTime = DateTime.parse("${data['quizDate']} ${data['startTime']}");
      final endTime = DateTime.parse("${data['quizDate']} ${data['endTime']}");
      _remainingTime = endTime.difference(DateTime.now());

      if (_remainingTime.isNegative) {
        setState(() {
          _isTimeOver = true;
        });
        return;
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime -= const Duration(seconds: 1);
          } else {
            _isTimeOver = true;
            _timer.cancel();
            submitForReal(); // Auto-submit when time ends
          }
        });
      });
    }
  }

  Future<List<Map<String, dynamic>>> getExam() async {
    final examSnapshot = await FirebaseFirestore.instance
        .collection('Exams')
        .doc(widget.examId)
        .get();

    if (!examSnapshot.exists || examSnapshot.data()?['questions'] == null) {
      throw Exception('Exam not found or missing questions field.');
    }

    final questions = List<String>.from(examSnapshot.data()?['questions'] ?? []);
    final questionDocs = await Future.wait(
      questions.map((questionId) async {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('Questions')
            .where('id', isEqualTo: questionId)
            .get();

        return querySnapshot.docs.isNotEmpty
            ? querySnapshot.docs.first.data()
            : throw Exception('Question not found for ID: $questionId');
      }),
    );

    if (examSnapshot.data()?['isRandom'] == true) {
      questionDocs.shuffle();
    }

    return questionDocs;
  }

  void submitForReal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }

    final examData = await _examFuture;
    final grade = calculateGrade(examData);

    final submission = {
      'user': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'exam': widget.examId,
      'grade': grade,
      'submitted': 1,
      'answers': _answers,
    };

    await FirebaseFirestore.instance.collection('Answers').add(submission);

    Navigator.of(context).pushReplacementNamed('/homeStudent');
  }

  double calculateGrade(List<Map<String, dynamic>> questions) {
    int totalPoints = 0;
    int obtainedPoints = 0;

    for (final question in questions) {
      final id = question['id'];
      final correctOption = question['correctOption'];
      final points = (question['points'] ?? 0) as int;

      if (question['type'] != 'Text' &&
          _answers[id] != null &&
          _answers[id] == correctOption) {
        obtainedPoints += points;
      }

      if (question['type'] != 'Text') {
        totalPoints += points;
      }
    }

    return (totalPoints > 0) ? (obtainedPoints / totalPoints) * 10 : 0;
  }

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
            onPressed: FirebaseAuth.instance.signOut,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _examFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty || _isTimeOver) {
            return const Center(
              child: Text("No quizzes available or time is over."),
            );
          }

          final questions = snapshot.data!;
          final currentQuestion = questions[_currentIndex];

          return Column(
            children: [
              // Timer
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Time Remaining: ${_remainingTime.inMinutes}:${_remainingTime.inSeconds % 60}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // Current Question
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentQuestion['text'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Answer Options
                    if (currentQuestion['type'] == 'MCQ' ||
                        currentQuestion['type'] == 'True/False')
                      Wrap(
                        spacing: 10,
                        children: (currentQuestion['options'] ?? [])
                            .map<Widget>((option) => ChoiceChip(
                                  label: Text(option),
                                  selected: _answers[currentQuestion['id']] == option,
                                  onSelected: (selected) {
                                    setState(() {
                                      _answers[currentQuestion['id']] = selected ? option : null;
                                    });
                                  },
                                ))
                            .toList(),
                      ),

                    if (currentQuestion['type'] == 'Text')
                      TextField(
                        controller: TextEditingController(
                            text: _answers[currentQuestion['id']] ?? ''),
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
                  ],
                ),
              ),

              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _goToPreviousQuestion,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  ElevatedButton(
                    onPressed: submitForReal,
                    child: const Text('Submit'),
                  ),
                  IconButton(
                    onPressed: () => _goToNextQuestion(questions.length),
                    icon: const Icon(Icons.arrow_forward),
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
