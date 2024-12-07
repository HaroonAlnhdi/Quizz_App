import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeViewStudent extends StatefulWidget {
  const HomeViewStudent({Key? key}) : super(key: key);

  @override
  State<HomeViewStudent> createState() => _HomeViewStudentState();
}

class _HomeViewStudentState extends State<HomeViewStudent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0; // Current index for the nav bar

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
          .map((doc) => doc.data() as Map<String, dynamic>)
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

        if (!mounted) return; // Prevent UI updates on disposed widgets
        setState(() {});
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.purple,
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
                        children: [
                          for (var classInfo in classes)
                            ExpansionTile(
                              title: Text(
                                classInfo['name'] ?? 'Class Name',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  'Course Number: ${classInfo['number'] ?? 'N/A'}'),
                              children: [
                                ListTile(
                                  title: const Text('Class Code'),
                                  subtitle: Text(classInfo['code'] ?? 'N/A'),
                                ),
                              ],
                            ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          // Profile screen placeholder
          FutureBuilder<Map<String, dynamic>>(
              future: _getUserInfo(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
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
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.blue.shade700,
                                ),
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
                              'Second Name: ${userInfo['lastName'] ?? 'N/A'}',
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

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String? classCode = await showDialog<String>(
            context: context,
            builder: (context) {
              TextEditingController controller = TextEditingController();
              return AlertDialog(
                title: const Text('Join Class'),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter class code',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, controller.text),
                    child: const Text('Join'),
                  ),
                   ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/quizPage');
          },
          child: Text('Go to Quiz Page'),
        ),
                ],
              );
            },
          );

          if (classCode != null && classCode.isNotEmpty) {
            _joinClass(classCode);
          }
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.purple,

      ),
    );
  }
}
