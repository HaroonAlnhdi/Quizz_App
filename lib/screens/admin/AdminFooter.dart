import 'package:flutter/material.dart';
import 'package:quiz_app/screens/admin/CreateExamPage.dart';
import 'package:quiz_app/screens/admin/HomeViewAdmin.dart'; // Import CreateExamPage

class AdminFooter extends StatefulWidget {
  const AdminFooter({super.key});

  @override
  State<AdminFooter> createState() => _AdminFooterState();
}

class _AdminFooterState extends State<AdminFooter> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateExamPage()),
        );
        break;
      case 2:
        print('Profile');
        break;
      default:
       Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeViewAdmin()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
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
    );
  }
}