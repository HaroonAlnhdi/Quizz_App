import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_app/screens/studen/NavViewStudent.dart';

class QuizzesPage extends StatefulWidget {
  final String classId;

  QuizzesPage({Key? key, required this.classId}) : super(key: key);

  @override
  _QuizzesPageState createState() => _QuizzesPageState();
}

class _QuizzesPageState extends State<QuizzesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;

  Future<Map<String, dynamic>> _getUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      return userSnapshot.data() as Map<String, dynamic>? ?? {};
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> _getClassExams(String classId) async {
    QuerySnapshot examSnapshot = await FirebaseFirestore.instance
        .collection('Exams')
        .where('class', isEqualTo: classId)
        .get();
    return examSnapshot.docs
        .map((doc) => {...(doc.data() as Map<String, dynamic>), 'id': doc.id})
        .toList();
  }

  Future<bool> _hasUserSubmittedQuiz(String quizId) async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    final QuerySnapshot answerSnapshot = await _firestore
        .collection('Answers')
        .where('exam', isEqualTo: quizId)
        .where('user', isEqualTo: user.uid)
        .limit(1)
        .get();

    return answerSnapshot.docs.isNotEmpty;
  }

  Future<void> _startQuiz(String quizId) async {
    bool alreadySubmitted = await _hasUserSubmittedQuiz(quizId);
    if (alreadySubmitted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Quiz Already Submitted'),
            content: const Text('You have already submitted this quiz.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Start Quiz' , style: TextStyle(color: Colors.purple)),
            content: const Text(
                'Are you sure you want to start the quiz? Once started, you cannot go back.' , style: TextStyle(color: Colors.black)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/quizPage', arguments: quizId);
                },
                child: const Text('Start' , style: TextStyle(color: Colors.purple , fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    }
  }

bool _isQuizAccessible(Map<String, dynamic> quiz) {
  DateTime now = DateTime.now(); // Current date and time in local timezone
  // print("Current time: $now"); // Debugging: Log the current time

  try {
    // Parse quiz date
    DateTime quizDate = DateTime.parse(quiz['quizDate']).toLocal();  // Convert to local time
    // print("Quiz date: $quizDate");

    // Parse start and end times
    List<String> startParts = quiz['startTime'].split(":");
    List<String> endParts = quiz['endTime'].split(":");

    // Combine quizDate with startTime and endTime
    DateTime quizStart = DateTime(
      quizDate.year,
      quizDate.month,
      quizDate.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );
    
    DateTime quizEnd = DateTime(
      quizDate.year,
      quizDate.month,
      quizDate.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    // Debugging: log the comparisons
    // print("Quiz start: $quizStart");
    // print("Quiz end: $quizEnd");
    // print("Is current time after quiz start? ${now.isAfter(quizStart)}");
    // print("Is current time before quiz end? ${now.isBefore(quizEnd)}");

    return now.isAfter(quizStart) && now.isBefore(quizEnd);
  } catch (e) {
    // print("Error in parsing date or time: $e");
    return false;
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Student Quizzes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.notifications, color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
            onPressed: ()  {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      drawer: NavViewStudent(
        getUserInfo: _getUserInfo,
        onDrawerItemTapped: (index) {
          setState(() {
            _selectedIndex = index;
            Navigator.of(context).pop();
          });
        },
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getClassExams(widget.classId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No quizzes found for this class.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
          } else {
            final quizzes = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Available Quizzes',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 3 / 3.5,
                    ),
                    itemCount: quizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = quizzes[index];
                      final isAccessible = _isQuizAccessible(quiz);

                      return GestureDetector(
                        onTap: isAccessible ? () => _startQuiz(quiz['id']) : null,
                        child: Card(
                          color: isAccessible ? Colors.white : Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.quiz_outlined,
                                      size: 45,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        quiz['title'] ?? 'Untitled Quiz',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isAccessible ? Colors.black : Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Date: ${quiz['quizDate']}'),
                                        Text('Start: ${quiz['startTime']}'),
                                        Text('End: ${quiz['endTime']}'),
                                        Text('Submissions: ${quiz['submissionLimit']}'),
                                        const SizedBox(height: 8),
                                        if (isAccessible)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 2.0, horizontal: 20.0),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.shade50,
                                              border: Border.all(color: Colors.purple, width: 1.0),
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                            child: const Text(
                                              "Start",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.purple,
                                                fontSize: 16,
                                              ),
                                            ),
                                          )
                                        else
                                          const Text(
                                            "Not Accessible",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}