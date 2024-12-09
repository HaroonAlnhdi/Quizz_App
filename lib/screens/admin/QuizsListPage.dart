import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiz_app/screens/admin/AdminAppBar.dart';

class QuizsListPage extends StatefulWidget {
  const QuizsListPage({super.key});

  @override
  State<QuizsListPage> createState() => _QuizsListPageState();
}

class _QuizsListPageState extends State<QuizsListPage> {
  String searchQuery = ""; // Variable to store search input

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    return Scaffold(
      appBar: const AdminAppBar(title: "Quizs List"),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText: 'Search Quizzes',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('Exams')
                  .where('createdBy', isEqualTo: userEmail)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No quizzes available.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                // Filter quizzes based on the search query
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final title = (doc['title'] as String).toLowerCase();
                  return title.contains(searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No quizzes match your search.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];

                    return Card(
                      color: const Color.fromARGB(255, 246, 227, 253),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.quiz,
                                  size: 40, color: Colors.blue),
                              title: Text(
                                doc['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                doc['description'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: PopupMenuButton(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditQuizPage(
                                          quizId: doc.id,
                                          initialData: doc,
                                        ),
                                      ),
                                    );
                                  } else if (value == 'delete') {
                                    FirebaseFirestore.instance
                                        .collection('Exams')
                                        .doc(doc.id)
                                        .delete();
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('Edit'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete),
                                      title: Text('Delete'),
                                    ),
                                  ),
                                ],
                                child: const Icon(Icons.more_vert),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person, color: Colors.grey),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                      'Created By: ${doc['createdBy']}'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.timer, color: Colors.grey),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                      'Start: ${doc['startTime']} - End: ${doc['endTime']}'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.history_toggle_off,
                                    color: Colors.grey),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                      'Submission Limit: ${doc['submissionLimit']}'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: Colors.grey),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                      'Created At: ${doc['createdAt'].toDate()}'),
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
      bottomSheet: Container(
        width: double.infinity,
        color: const Color(0xFF7826b5),
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




class EditQuizPage extends StatefulWidget {
  final String quizId;
  final QueryDocumentSnapshot<Object?> initialData;

  const EditQuizPage({super.key, required this.quizId, required this.initialData});

  @override
  State<EditQuizPage> createState() => _EditQuizPageState();
}

class _EditQuizPageState extends State<EditQuizPage> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController submissionLimitController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialData['title']);
    descriptionController = TextEditingController(text: widget.initialData['description']);
    submissionLimitController = TextEditingController(text: '${widget.initialData['submissionLimit']}');
  }

  void _updateQuiz() async {
    await FirebaseFirestore.instance.collection('Exams').doc(widget.quizId).update({
      'title': titleController.text,
      'description': descriptionController.text,
      'submissionLimit': int.tryParse(submissionLimitController.text) ?? 0,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quiz updated successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Quiz'),
        backgroundColor: Colors.purple.shade700,
        elevation: 5,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.purple.shade600),
                  hintText: 'Enter quiz title',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple.shade700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description Field
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.purple.shade600),
                  hintText: 'Enter quiz description',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple.shade700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Submission Limit Field
              TextField(
                controller: submissionLimitController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Submission Limit',
                  labelStyle: TextStyle(color: Colors.purple.shade600),
                  hintText: 'Enter submission limit',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple.shade700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Centered Save Changes Button
              Center(
                child:ElevatedButton(
                    onPressed: _updateQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700, // Button color
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40), // Increase padding for bigger button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),

              ),
            ],
          ),
        ),
      ),
    );
  }
}
