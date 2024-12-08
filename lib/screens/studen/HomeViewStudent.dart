import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_app/screens/studen/NavViewStudent.dart';
import 'package:quiz_app/screens/studen/QuizzesPage.dart';
import 'StudentJoinClass.dart';

class HomeViewStudent extends StatefulWidget {
  const HomeViewStudent({Key? key}) : super(key: key);

  @override
  State<HomeViewStudent> createState() => _HomeViewStudentState();
}

class _HomeViewStudentState extends State<HomeViewStudent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0; // Current index for navigation (0 = Home, 1 = Profile)

  Future<Map<String, dynamic>> _getUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(user.uid).get();
      return userSnapshot.data() as Map<String, dynamic>? ?? {};
    }
    return {};
  }

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

  Future<void> _joinClass(String classCode) async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot classSnapshot = await _firestore
          .collection('classes')
          .where('code', isEqualTo: classCode)
          .get();

      if (classSnapshot.docs.isNotEmpty) {
        String classId = classSnapshot.docs.first.id;
        await _firestore
            .collection('classes')
            .doc(classId)
            .update({'students': FieldValue.arrayUnion([user.uid])});

        if (!mounted) return;
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the class!')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid class code.')),
        );
      }
    }
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
        title: const Text('Student Dashboard' , style: TextStyle(color: Colors.white , fontWeight: FontWeight.bold) , ),
        backgroundColor: Colors.purple,
      ),
      drawer: NavViewStudent(
        getUserInfo: _getUserInfo,
        onDrawerItemTapped: _onDrawerItemTapped,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home screen content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: _getUserInfo(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError || snapshot.data == null) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Error fetching user info'),
                      );
                    } else {
                      final userInfo = snapshot.data!;
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.all(16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: Colors.purple.shade100,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.purple),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${userInfo['firstName'] ?? 'N/A'} ${userInfo['lastName'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.email, color: Colors.purple),
                                  const SizedBox(width: 8),
                                  Text(
                                    userInfo['email'] ?? 'No email available',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getStudentClasses(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError || snapshot.data == null) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Error fetching classes'),
                      );
                    } else {
                      final classes = snapshot.data!;
                      return Column(
                        children: classes.map((classInfo) {
                          return ExpansionTile(
                            title: Text(
                              classInfo['name'] ?? 'Class Name',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Course Number: ${classInfo['number'] ?? 'N/A'}'),
                            children: [
                              ListTile(
                                title: const Text('Class Code'),
                                subtitle: Text(classInfo['code'] ?? 'N/A'),
                              ),
                              ListTile(
                                title: const Text('View Quizzes'),
                                trailing: const Icon(Icons.arrow_forward),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          QuizzesPage(classId: classInfo['id']),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          // Profile screen
          FutureBuilder<Map<String, dynamic>>(
            future: _getUserInfo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data == null) {
                return const Center(
                  child: Text(
                    'Error fetching profile info',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                );
              } else {
                final userInfo = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, size: 40, color: Colors.blue.shade700),
                              const SizedBox(width: 16),
                              Text(
                                'Profile Info',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 1),
                          Text(
                            'First Name: ${userInfo['firstName'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Last Name: ${userInfo['lastName'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email: ${userInfo['email'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              
            },
          ),

        ],

      ),
      floatingActionButton: StudentJoinClass(
        onJoinClass: _joinClass,
      ),
    );
  }
}
