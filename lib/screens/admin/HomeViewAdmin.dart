import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_app/screens/admin/AdminAppBar.dart';
import 'package:quiz_app/screens/admin/CreateExamPage.dart';
import 'package:quiz_app/screens/admin/CreateClass.dart';
// import 'package:quiz_app/screens/admin/QuizsListPage.dart';

class HomeViewAdmin extends StatefulWidget {
  const HomeViewAdmin({super.key});

  @override
  State<HomeViewAdmin> createState() => _HomeViewAdminState();
}

class _HomeViewAdminState extends State<HomeViewAdmin> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  Future<Map<String, dynamic>> _getUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      return userDoc.data() as Map<String, dynamic>;
    }
    return {};
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(title: 'Dashboard'),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _getUserInfo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No user data found'));
              } else {
                var userInfo = snapshot.data!;
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Center(
                        child: Card(
                          elevation: 2,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          color: const Color(0xFF7826b5),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person,
                                        color: Colors.white, size: 25),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Welcome ${userInfo['firstName']} ${userInfo['lastName']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    const Icon(Icons.email,
                                        color: Colors.white, size: 25),
                                    const SizedBox(width: 10),
                                    Text(
                                      userInfo['email'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        padding: const EdgeInsets.all(12.0),
                        crossAxisSpacing: 12.0,
                        mainAxisSpacing: 12.0,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _onItemTapped(1);
                            },
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              color: Colors.blue,
                              child: const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.create,
                                          color: Colors.white, size: 40),
                                      SizedBox(height: 8),
                                      Text(
                                        'Create Exam',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _onItemTapped(2),
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              color: Colors.green,
                              child: const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.grade,
                                          color: Colors.white, size: 40),
                                      SizedBox(height: 8),
                                      Text(
                                        'Exam Grades',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/QuizsListPage');
                            },
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              color: Colors.orange,
                              child: const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.list,
                                          color: Colors.white, size: 40),
                                      SizedBox(height: 8),
                                      Text(
                                        'Quizs List',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              _auth.signOut();
                              Navigator.pushNamed(context, '/login');
                            },
                            child: Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              color: Colors.red,
                              child: const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.logout,
                                          color: Colors.white, size: 40),
                                      SizedBox(height: 8),
                                      Text(
                                        'Logout',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Add this inside the `children` list of GridView
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const CreateClass()),
                              );
                            },
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              color: Colors.purple,
                              child: const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.class_,
                                          color: Colors.white, size: 50),
                                      SizedBox(height: 10),
                                      Text(
                                        'Create Class',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          

                        ],
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          CreateExamPage(),
          Center(child: Text('Profile Page')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF7826b5),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ExamGradesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exam Grades'),
      ),
      body: Center(
        child: Text('Exam Grades Page'),
      ),
    );
  }
}
