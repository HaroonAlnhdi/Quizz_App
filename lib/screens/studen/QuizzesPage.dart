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

  Future<int> _getSubmissionLimit(String quizId) async {
    // Fetch the submission limit for the specific quiz and user
    DocumentSnapshot quizSnapshot = await FirebaseFirestore.instance
        .collection('Submissions')
        .doc(quizId)
        .get();

    if (quizSnapshot.exists) {
      Map<String, dynamic>? data = quizSnapshot.data() as Map<String, dynamic>?;
      return data?['submissionLimit'] ?? 1; // Default to 0 if not set
    }
    return 0; // If the quiz doesn't have a record, default to 0
  }

  Future<void> _reduceSubmissionLimit(String quizId) async {
    // Reduce the submission limit by 1
    DocumentReference quizRef =
        FirebaseFirestore.instance.collection('Submissions').doc(quizId);

    DocumentSnapshot snapshot = await quizRef.get();
    if (snapshot.exists) {
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      int currentLimit = data?['submissionLimit'] ?? 0;

      if (currentLimit > 0) {
        await quizRef.update({'submissionLimit': currentLimit - 1});
      }
    }
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
                return FutureBuilder<int>(
                  future: _getSubmissionLimit(quiz['id']),
                  builder: (context, limitSnapshot) {
                    if (limitSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        title: Text('Loading...'),
                        subtitle: Text('Please wait...'),
                      );
                    } else if (limitSnapshot.hasError) {
                      return ListTile(
                        title: Text(quiz['title'] ?? 'Untitled Quiz'),
                        subtitle: const Text('Error fetching submission limit'),
                      );
                    } else {
                      final submissionLimit = limitSnapshot.data ?? 0;
                      return ListTile(
                        title: Text(quiz['title'] ?? 'Untitled Quiz'),
                        subtitle: Text('Date: ${quiz['quizDate']} | Attempts left: $submissionLimit'),
                        onTap: submissionLimit > 0
                            ? () async {
                                await _reduceSubmissionLimit(quiz['id']);
                                Navigator.pushNamed(
                                  context,
                                  '/quizPage',
                                  arguments: quiz['id'],
                                );
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'You have reached the maximum number of attempts for this quiz.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                      );
                    }
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
