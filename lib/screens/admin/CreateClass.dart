import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_app/screens/admin/AdminAppBar.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class CreateClass extends StatefulWidget {
  const CreateClass({super.key});

  @override
  State<CreateClass> createState() => _CreateClassState();
}

class _CreateClassState extends State<CreateClass> {
  final TextEditingController _classNumberController = TextEditingController();
  final TextEditingController _classNameController = TextEditingController();
  final _uuid = Uuid();

  void _addClass() async {
    if (_classNumberController.text.isEmpty ||
        _classNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all the information')),
      );
      return;
    }

    String newClassCode =
        _uuid.v4().substring(0, 6); // Generate a unique 6-character code

    await FirebaseFirestore.instance.collection('classes').add({
      'number': _classNumberController.text,
      'name': _classNameController.text,
      'code': newClassCode,
      'teacher': FirebaseAuth.instance.currentUser!.uid, // Set the teacher field to the logged-in user's ID
      'students': [], // Initialize an empty list of students
    });

    _classNumberController.clear();
    _classNameController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Class added successfully')),
    );
  }

  void _navigateToClassDetails(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassDetailsPage(docId: doc.id),
      ),
    );
  }

  void _deleteClass(String docId) async {
    await FirebaseFirestore.instance.collection('classes').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Class deleted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(title: 'Create Class'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Row(
                children: [
                  Icon(Icons.arrow_back),
                  SizedBox(width: 4),
                  Text('Back'),
                ],
              ),
            ),
            const SizedBox(height: 5.0),
            const Text(
              'Create a new class',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7826B5),
              ),
            ),
            TextField(
              controller: _classNumberController,
              decoration: const InputDecoration(
                labelText: 'Class Code',
              ),
            ),
            TextField(
              controller: _classNameController,
              decoration: const InputDecoration(
                labelText: 'Class Name',
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
               backgroundColor: Color(0xFF7826B5),
              ),
              onPressed: _addClass,
              child: const Text('Add Class' , style: TextStyle(color: Colors.white ),),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Classes : ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7826B5),
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No classes available.",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var classData = doc.data() as Map<String, dynamic>;

                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Class Code: ${classData['number']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteClass(doc.id),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Class Name: ${classData['name']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(
                                          text: classData['code']));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Code copied to clipboard: ${classData['code']}' , style: TextStyle(color: Colors.white),
                                              
                                              ),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Code: ${classData['code']}',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _navigateToClassDetails(doc),
                                    icon: const Icon(Icons.arrow_forward),
                                    label: const Text('Details'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF7826B5),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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



class ClassDetailsPage extends StatelessWidget {
  final String docId;

  const ClassDetailsPage({required this.docId, super.key});

  void _deleteStudent(BuildContext context, String studentName) async {
    var doc =
        await FirebaseFirestore.instance.collection('classes').doc(docId).get();
    var classData = doc.data() as Map<String, dynamic>;
    List students = List.from(classData['students']);
    students.removeWhere((student) {
      if (student is String) {
        return student == studentName;
      } else {
        return student['name'] == studentName;
      }
    });

    await FirebaseFirestore.instance
        .collection('classes')
        .doc(docId)
        .update({'students': students});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$studentName has been removed from the class'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(title: 'Class Details'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes')
              .doc(docId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var classData = snapshot.data!.data() as Map<String, dynamic>;
            var students = classData['students']?.map((student) {
                  if (student is String) {
                    return {'name': student}; // Use the string as the name
                  } else {
                    return student;
                  }
                }).toList() ??
                [];

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class Information Section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class Code: ${classData['number']}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Class Name: ${classData['name']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Students: ${students.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Students Section
                  const Text(
                    'Students',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  students.isEmpty
                      ? const Center(
                          child: Text(
                            'No students have been added to this class.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student =
                                students[index] as Map<String, dynamic>;
                            return Card(
                              margin:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  student['name'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteStudent(
                                      context, student['name']),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            );
          },
        ),
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
