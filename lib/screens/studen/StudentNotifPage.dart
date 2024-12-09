import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentNotifPage extends StatefulWidget {
  const StudentNotifPage({super.key});

  @override
  State<StudentNotifPage> createState() => _StudentNotifPageState();
}

class _StudentNotifPageState extends State<StudentNotifPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchAndStoreNotifications();
  }

  Future<void> _fetchAndStoreNotifications() async {
    var examsSnapshot = await _firestore.collection('Exams').get();
    for (var doc in examsSnapshot.docs) {
      var data = doc.data();
      await _firestore.collection('Notifications').doc(doc.id).set(data);
    }
  }

  Stream<List<DocumentSnapshot>> _getNotifications() {
    return _firestore.collection('Notifications').snapshots().map((snapshot) {
      return snapshot.docs.toList();
    });
  }

  Future<void> _clearNotification(String docId) async {
    await _firestore.collection('Notifications').doc(docId).delete();
  }

  Future<void> _clearAllNotifications(
      List<DocumentSnapshot> notifications) async {
    for (var notification in notifications) {
      await _firestore
          .collection('Notifications')
          .doc(notification.id)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Student Notifications' , style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
       
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notifications available.'));
          }

          var notifications = snapshot.data!;

          return Column(
            children: [
              if (notifications.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7826b5),
                    ),
                    onPressed: () {
                      _clearAllNotifications(notifications);
                    },
                    child: const Text(
                      'Clear All Notifications',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    var notification =
                        notifications[index].data() as Map<String, dynamic>;
                    // Use the date and time strings directly
                    String quizDate = notification['quizDate'] ?? 'No Date';
                    String startTime = notification['startTime'];
                    String endTime = notification['endTime'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(notification['title']),
                          subtitle: Text(
                            'Created by: ${notification['createdBy']}\nDate: $quizDate\nStart Time: $startTime\nEnd Time: $endTime',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _clearNotification(notifications[index].id);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
