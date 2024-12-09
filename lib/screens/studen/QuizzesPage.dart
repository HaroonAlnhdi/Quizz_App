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
  // ignore: unused_field
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

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Student Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        
        actions: [
          IconButton(onPressed: (){}, icon: const Icon(Icons.notifications , color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.logout , color: Colors.white) ,
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      drawer: NavViewStudent(
        getUserInfo: _getUserInfo,
        onDrawerItemTapped: _onDrawerItemTapped,
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
                crossAxisCount: 2, // Number of cards in a row
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 3 / 3.5, // Increased height for better spacing
              ),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/quizPage',
                      arguments: quiz['id'],
                    );
                  },
                  child: Card(
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
                                 Container(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 20.0),
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