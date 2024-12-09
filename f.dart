import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_app/screens/studen/QuizzesPage.dart';

class HomeViewStudent extends StatefulWidget {
  const HomeViewStudent({Key? key}) : super(key: key);

  @override
  State<HomeViewStudent> createState() => _HomeViewStudentState();
}

class _HomeViewStudentState extends State<HomeViewStudent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _getStudentClasses() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot classSnapshot = await _firestore
          .collection('classes')
          .where('students', arrayContains: user.uid)
          .get();
      return classSnapshot.docs
          .map((doc) => {...(doc.data() as Map<String, dynamic>), 'id': doc.id})
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Classes"),
        backgroundColor: Colors.purple,
      ),
      body: 
      
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _getStudentClasses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text("Error fetching classes."));
          } else {
            final classes = snapshot.data!;
            if (classes.isEmpty) {
              return const Center(
                child: Text(
                  "No classes found.",
                  style: TextStyle(fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              itemCount: classes.length,
              itemBuilder: (BuildContext context, int index) {
                final classInfo = classes[index];
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ClassDetailPage(
                        heroTag: index,
                        classInfo: classInfo,
                      ),
                    ));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Hero(
                          tag: index,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.purple.shade100,
                            child: const Icon(Icons.class_, size: 40, color: Colors.purple),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                classInfo['name'] ?? 'Class Name',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                'Course Number: ${classInfo['number'] ?? 'N/A'}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
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

class ClassDetailPage extends StatelessWidget {
  final int heroTag;
  final Map<String, dynamic> classInfo;

  const ClassDetailPage({Key? key, required this.heroTag, required this.classInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(classInfo['name'] ?? "Class Details")),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Hero(
                tag: heroTag,
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.purple.shade100,
                  child: const Icon(Icons.class_, size: 80, color: Colors.purple),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class Name: ${classInfo['name'] ?? 'N/A'}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Course Number: ${classInfo['number'] ?? 'N/A'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Class Code: ${classInfo['code'] ?? 'N/A'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => QuizzesPage(classId: classInfo['id']),
                      ));
                    },
                    icon: const Icon(Icons.quiz),
                    label: const Text('View Quizzes'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
