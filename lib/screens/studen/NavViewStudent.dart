import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quiz_app/screens/LoginView.dart';

class NavViewStudent extends StatelessWidget {
  final Future<Map<String, dynamic>> Function() getUserInfo;
  final Function(int) onDrawerItemTapped;

  const NavViewStudent({
    Key? key,
    required this.getUserInfo,
    required this.onDrawerItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.purple,
            ),
            child: FutureBuilder<Map<String, dynamic>>(
              future: getUserInfo(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text(
                    'Welcome!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                final userInfo = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person, size: 40, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      '${userInfo['firstName'] ?? 'Student'} ${userInfo['lastName'] ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      userInfo['email'] ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
            ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF7826B5)),
            title: const Text('Home', style: TextStyle(color: Color(0xFF7826B5), fontWeight: FontWeight.bold)),
            onTap: () => onDrawerItemTapped(0),
            ),
            ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF7826B5)),
            title: const Text('Profile', style: TextStyle(color: Color(0xFF7826B5), fontWeight: FontWeight.bold)),
            onTap: () => onDrawerItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Color(0xFF7826B5)),
              title: const Text('Quiz List', style: TextStyle(color: Color(0xFF7826B5), fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pushNamed(context, '/QuizsListPage');
              },
            ),
            ListTile(
              leading: const Icon(Icons.score, color: Color(0xFF7826B5)),
              title: const Text('Quiz Degrees', style: TextStyle(color: Color(0xFF7826B5), fontWeight: FontWeight.bold)),
              onTap: () {},
            ),
            ListTile(
            leading: const Icon(Icons.info, color: Color(0xFF7826B5)),
            title: const Text('About', style: TextStyle(color: Color(0xFF7826B5), fontWeight: FontWeight.bold)),
            onTap: () {},
            ),
            ListTile(
            leading: const Icon(Icons.contact_page, color: Color(0xFF7826B5)),
            title: const Text('Contact Us', style: TextStyle(color: Color(0xFF7826B5), fontWeight: FontWeight.bold)),
            onTap: () {},
            ),
            ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF7826B5)),
            title: const Text('Settings', style: TextStyle(color: Color(0xFF7826B5), fontWeight: FontWeight.bold)),
            onTap: () {},
            ),
            ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF7826B5)),
            title: const Text('Logout', style: TextStyle(color: Color(0xFF7826B5), fontWeight: FontWeight.bold)),
            onTap: () {
               FirebaseAuth.instance.signOut().then((_) {
              Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginView()),
              );
              });
            },
            ),
        ],
      ),
    );
  }
}