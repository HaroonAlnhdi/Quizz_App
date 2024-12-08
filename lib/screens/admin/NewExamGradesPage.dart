import 'package:cloud_firestore/cloud_firestore.dart';
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
              List students = List.from(classData['students']);

              return ExpansionTile(
                title: Text('$className - $classNumber'),
                children: [
                  FutureBuilder(
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
                              return FutureBuilder(
                                future: _fetchStudentGradeForExam(students[studentIndex], examData.id),
                                builder: (context, gradeSnapshot) {
                                  if (gradeSnapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  String studentName = 'Student $studentIndex'; 
                                  String grade = gradeSnapshot.data ?? 'No Grade';

                                  return ListTile(
                                    title: Text('$studentName'),
                                    subtitle: Text('Grade: $grade'),
                                  );
                                },
                              );
                            }),
                          );
                        }),
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
  Future<String?> _fetchStudentGradeForExam(String studentId, String examId) async {
    var answerSnapshot = await FirebaseFirestore.instance
        .collection('Answers')
        .where('user', isEqualTo: studentId)
        .where('exam', isEqualTo: examId)
        .get();

    if (answerSnapshot.docs.isEmpty) return null; 
    return answerSnapshot.docs.first['grade'] ?? 'No Grade';
  }
}
