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
  late Future<List<Map<String, dynamic>>> _examFuture; // Cache the future
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _examFuture = getExam(); // Assign the future once in initState
  }

  void dispose() {
    _controller.dispose(); // Clean up the controller when the widget is removed
    super.dispose();
  }

  void _handleNextButtonPress() {
    _controller.clear();
  }

  double calculateGrade( List<Map<String, dynamic>> questions) {
    var total = questions.length;
    var correct = 0;

    for (var question in questions) {
      var id = question['id'];
      var correctAnswer = question['answer'];
      var userAnswer = Answers[id];

      if (correctAnswer == userAnswer) {
        correct++;
      }
    }

    return (correct / total) * 10;
    
  }

  submitForReal( List<Map<String, dynamic>> questions) {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not found.');
    }

    Answers['user'] = user.uid;
    Answers['timestamp'] = FieldValue.serverTimestamp();
    Answers['exam'] = widget.ExamId;
    Answers['grade'] = calculateGrade(questions);
    print(Answers);

    FirebaseFirestore.instance.collection('Answers').add({'Answers': Answers,});

    Navigator.of(context).pop(); // Close the dialog
    Navigator.of(context).pushReplacementNamed('/homeStudent');
  }

  var Answers = { };

  Future<List<Map<String, dynamic>>> getExam() async {
    var examSnapshot = await FirebaseFirestore.instance
        .collection('Exams')
        .doc(widget.ExamId)
        .get();


    if (!examSnapshot.exists || examSnapshot.data()?['questions'] == null) {
      throw Exception('Exam not found or missing questions field.');
    }
    var questions = examSnapshot.data()?['questions'] as List<dynamic>;

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
      body: 
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _examFuture, // Use cached future
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
               ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Submit Answers'),
                              content: const Text('Are you sure you want to submit your answers?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(); // Close the dialog
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(); // Close the dialog
                                    submitForReal(questions);
                                  },
                                  child: const Text('Submit'),
                                ),
                              ],
                            );
                          },
                        );
                        print(Answers);
                        },
                      child: const Text('Submit Answers'),
            ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                      ],
                    ),
                  ),
                ),
              ),
               if (currentQuestion['type'] == 'MCQ')
                Wrap(
                  spacing: 20.0, // Space between buttons horizontally
                  runSpacing: 10.0, // Space between rows of buttons
                  children: currentQuestion['options']
                      .map<Widget>((option) => SizedBox(
                            width: 150, // Set a minimum width for buttons
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                });
                                Answers[currentQuestion['id']] == option?Answers[currentQuestion['id']] = '': Answers[currentQuestion['id']] = option;
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Answers[currentQuestion['id']]==option?Colors.blue:Colors.purple,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20.0, // Padding inside the button
                                  horizontal: 20.0,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  option,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),




                        if (currentQuestion['type'] == 'True/False')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            // mainAxisAlignment: MainAxisAlignment.center,
                            children: [                              
                              ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  Answers[currentQuestion['id']] == 'True'?Answers[currentQuestion['id']] = '': Answers[currentQuestion['id']] = 'True';
                                  print(Answers);
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Answers[currentQuestion['id']]=='True'?Colors.blue:Colors.purple,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20.0, // Padding inside the button
                                  horizontal: 20.0,
                                ),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                    'True',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),


                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  Answers[currentQuestion['id']] == 'False'?Answers[currentQuestion['id']] = '': Answers[currentQuestion['id']] = 'False';
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Answers[currentQuestion['id']]=='False'?Colors.blue:Colors.purple,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20.0, // Padding inside the button
                                  horizontal: 20.0,
                                ),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                    'False',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),


                            
                            ],
                          ),
                        if (currentQuestion['type'] == 'Text')
                          
                              TextField(
                                controller: TextEditingController(text: Answers[currentQuestion['id']]),
                                onChanged: (value) {
                                  setState(() {
                                    Answers[currentQuestion['id']] = value;

                                  });
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter your answer',
                                ),
                              ),                              
                            
                          
                          
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _goToPreviousQuestion,
                      icon: const Icon(Icons.arrow_left),
                      iconSize: 40,
                      color: _currentIndex > 0 ? Colors.blue : Colors.grey,
                    ),
                    
                    IconButton(
                      onPressed: () => _goToNextQuestion(questions.length),
                      icon: const Icon(Icons.arrow_right),
                      iconSize: 40,
                      color: _currentIndex < questions.length - 1
                          ? Colors.blue
                          : Colors.grey,
                    ),

                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
