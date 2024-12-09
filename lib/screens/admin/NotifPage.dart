import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'AdminAppBar.dart';

class NotifPage extends StatefulWidget {
  const NotifPage({super.key});

  @override
  State<NotifPage> createState() => _NotifPageState();
}

class _NotifPageState extends State<NotifPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<DocumentSnapshot>> _getCompletedQuizzes() {
    // Get current time as string
    String currentTime = DateFormat('HH:mm').format(DateTime.now());

    return _firestore.collection('Exams').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        var quiz = doc.data() as Map<String, dynamic>;
        String endTime = quiz['endTime'];
        return endTime.compareTo(currentTime) <= 0;
      }).toList();
    });
  }

  Future<void> _clearNotification(String docId) async {
    await _firestore.collection('Exams').doc(docId).delete();
  }

  Future<void> _clearAllNotifications(List<DocumentSnapshot> quizzes) async {
    for (var quiz in quizzes) {
      await _firestore.collection('Exams').doc(quiz.id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(title: 'Notifications'),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _getCompletedQuizzes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No completed quizzes available.'));
          }

          var quizzes = snapshot.data!;

          return Column(
            children: [
              if (quizzes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7826b5),
                    ),
                    onPressed: () {
                      
                    },
                    child: const Text(
                      'Clear All Notifications',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    var quiz = quizzes[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(quiz['title']),
                      subtitle: const Text('Status: Completed'),
                      trailing: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                        
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: Container(
        width: double.infinity,
        color: Color(0xFF7826b5),
        height: 50,
        child: TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          label: const Text('Back', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
