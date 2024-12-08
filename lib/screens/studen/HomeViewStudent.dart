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
        title: const Text(
          'Student Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        
        actions: [
          IconButton(
            icon: const Icon(Icons.logout , color: Colors.white) ,
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      drawer:
       NavViewStudent(
        getUserInfo: _getUserInfo,
        onDrawerItemTapped: _onDrawerItemTapped,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          
          Column(
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
              Container(
                alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 15.0),
              padding: const EdgeInsets.all(8.0),
               width: double.infinity,
              decoration: BoxDecoration(   
                color: Colors.purple.shade50,
              ),
             child: const Text(
                'Your Classes ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                  
                ),
              ),
              ),
            Expanded(
  child: FutureBuilder<List<Map<String, dynamic>>>(
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
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 15.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  border: Border.all(color: Colors.purple, width: 1.0),
                  borderRadius: BorderRadius.circular(25.0),
                ),
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
)
            ],
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
                              Icon(Icons.person,
                                  size: 40, color: Colors.blue.shade700),
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
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Last Name: ${userInfo['lastName'] ?? 'N/A'}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email: ${userInfo['email'] ?? 'N/A'}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black54),
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

class ClassDetailPage extends StatelessWidget {
  final int heroTag;
  final Map<String, dynamic> classInfo;

  const ClassDetailPage({Key? key, required this.heroTag, required this.classInfo})
      : super(key: key);

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
                        builder: (context) =>
                            QuizzesPage(classId: classInfo['id']),
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
