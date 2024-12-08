import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizzesPage extends StatelessWidget {
  final String classId;

  const QuizzesPage({Key? key, required this.classId}) : super(key: key);

  Future<List<Map<String, dynamic>>> _getClassExams(String classId) async {
    QuerySnapshot examSnapshot = await FirebaseFirestore.instance
        .collection('Exams')
        .where('class', isEqualTo: classId)
        .get();
    return examSnapshot.docs
        .map((doc) => {...(doc.data() as Map<String, dynamic>), 'id': doc.id})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        backgroundColor: Colors.purple,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getClassExams(classId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No quizzes found for this class.'),
            );
          } else {
            final quizzes = snapshot.data!;
            return ListView.builder(
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return ListTile(
                  title: Text(quiz['title'] ?? 'Untitled Quiz'),
                  subtitle: Text('Date: ${quiz['quizDate']}'),
                  onTap: () {
                    print(quiz['id']);
                    Navigator.pushNamed(
                      context,
                      '/quizPage',
                      arguments: quiz['id'],
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
