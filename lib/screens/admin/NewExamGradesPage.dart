import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewExamGradesPage extends StatelessWidget {
  const NewExamGradesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Updated Exam'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getClasses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No classes found.'));
          }

          var classes = snapshot.data!;
          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              var classData = classes[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ExpansionTile(
                  title: Text(
                    classData['name'] ?? 'Unnamed Class',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Number: ${classData['number'] ?? 'N/A'}, Code: ${classData['code'] ?? 'N/A'}',
                  ),
                  children: [
                    FutureBuilder<List<Map<String, dynamic>>>( 
                      future: getExams(classData['id']),
                      builder: (context, ExamSnapshot) {
                        if (ExamSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (ExamSnapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Error: ${ExamSnapshot.error}'),
                          );
                        }

                        if (!ExamSnapshot.hasData || ExamSnapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No exams found.'),
                          );
                        }

                        var exams = ExamSnapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: exams.map((exam) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${exam['title']}',
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  // Fetch and show grade here
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getClasses() async {
    List<Map<String, dynamic>> classes = [];
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print('No user is logged in.');
      return classes;
    }

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .get();

      for (var doc in querySnapshot.docs) {
        var code = doc['code'] ?? 'No Code'; // Default value if no code
        classes.add({
          'id': doc.id,
          'code': code,
          'name': doc['name'] ?? 'Unnamed Class',
          'number': doc['number'] ?? 'N/A',
          'students': doc['students'] ?? [],
        });
      }
    } catch (e) {
      print('Error fetching classes: $e');
    }
    return classes;
  }

  Future<List<Map<String, dynamic>>> getExams(String? classCode) async {
    List<Map<String, dynamic>> exams = [];

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Exams')
          .where('class', isEqualTo: classCode)
          .get();

      for (var doc in querySnapshot.docs) {
        exams.add({
          'title': doc['title'],
          'id': doc.id,
          'class': doc['class'],
        });
      }
    } catch (e) {
      print('Error fetching exams: $e');
    }
    return exams;
  }

  // Function to get grade for a student in a specific exam
  Future<List<Map<String, String>>> getAnswers(String examCode) async {
    List<Map<String, String>> grades = [];
    try {
      QuerySnapshot gradeQuery = await FirebaseFirestore.instance
          .collection('grades')
          .where('exam', isEqualTo: examCode)
          .get();

      for (var doc in gradeQuery.docs) {
        grades.add({
          'grade': doc['grade'],
          'user': doc['user'],
        });
      }
    } catch (e) {
      print('Error fetching grades: $e');
    }
    return grades;
  }
}
