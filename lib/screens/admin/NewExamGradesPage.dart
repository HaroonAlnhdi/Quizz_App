import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class NewExamGradesPage extends StatelessWidget {
  const NewExamGradesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Updated Exam Grades'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (context, classesSnapshot) {
          if (classesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!classesSnapshot.hasData || classesSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Classes Available"));
          }

          return ListView.builder(
            itemCount: classesSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var classData = classesSnapshot.data!.docs[index];
              String className = classData['name'];
              String classNumber = classData['number'];
              List studentIds = List.from(classData['students']);

              return ExpansionTile(
                title: Text('$className - $classNumber'),
                children: [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchStudents(studentIds),
                    builder: (context, studentsSnapshot) {
                      if (studentsSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!studentsSnapshot.hasData || studentsSnapshot.data!.isEmpty) {
                        return const Center(child: Text("No Students Available"));
                      }

                      var students = studentsSnapshot.data!;
                      return FutureBuilder(
                        future: _fetchExamsForClass(classData.id),
                        builder: (context, examSnapshot) {
                          if (examSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!examSnapshot.hasData || examSnapshot.data!.docs.isEmpty) {
                            return const Center(child: Text("No Exams Available"));
                          }

                          return Column(
                            children: List.generate(examSnapshot.data!.docs.length, (examIndex) {
                              var examData = examSnapshot.data!.docs[examIndex];
                              String examTitle = examData['title'];

                              return ExpansionTile(
                                title: Text(examTitle),
                                children: List.generate(students.length, (studentIndex) {
                                  var student = students[studentIndex];
                                  String studentId = student['id'];
                                  String studentName = "${student['firstName']} ${student['lastName']}";

                                  return FutureBuilder<Map?>(
                                    future: _fetchStudentGradeForExam(studentId, examData.id),
                                    builder: (context, gradeSnapshot) {
                                      if (gradeSnapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }

                                      String grade = gradeSnapshot.data?['grade'] ?? 'No Grade';
                                      return ListTile(
                                        title: Text(studentName),
                                        subtitle: Text('Grade: $grade'),
                                      );
                                    },
                                  );
                                }),
                              );
                            }),
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Fetch exams for a specific class
  Future<QuerySnapshot> _fetchExamsForClass(String classId) {
    return FirebaseFirestore.instance
        .collection('Exams')
        .where('class', isEqualTo: classId)
        .get();
  }

  // Fetch student grade for a specific exam
  Future<Map?> _fetchStudentGradeForExam(String studentId, String examId) async {
    var answerSnapshot = await FirebaseFirestore.instance
        .collection('Answers')
        .where('user', isEqualTo: studentId)
        .where('exam', isEqualTo: examId)
        .get();

    if (answerSnapshot.docs.isEmpty) return null;
    return answerSnapshot.docs.first.data() as Map;
  }

  // Fetch student details based on student IDs
  Future<List<Map<String, dynamic>>> _fetchStudents(List studentIds) async {
    var studentsSnapshot = await FirebaseFirestore.instance.collection('users').get();
    return studentsSnapshot.docs
        .where((doc) => studentIds.contains(doc.id))
        .map((doc) => {
              'id': doc.id,
              'firstName': doc['firstName'],
              'lastName': doc['lastName'],
            })
        .toList();
  }
}
