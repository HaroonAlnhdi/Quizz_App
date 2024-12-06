import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_app/screens/admin/AdminAppBar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateExamPage extends StatefulWidget {
  const CreateExamPage({super.key});

  @override
  State<CreateExamPage> createState() => _CreateExamPageState();
}

class _CreateExamPageState extends State<CreateExamPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _submissionLimitController =
      TextEditingController();
  final List<Map<String, dynamic>> _questions = [];
  bool _isLoading = false;
  int _currentStep = 0;

  String? _getUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController questionController =
            TextEditingController();
        final TextEditingController optionAController = TextEditingController();
        final TextEditingController optionBController = TextEditingController();
        final TextEditingController optionCController = TextEditingController();
        final TextEditingController optionDController = TextEditingController();
        final TextEditingController correctOptionController =
            TextEditingController();

        return AlertDialog(
          title: const Text('Add Question'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(labelText: 'Question Text'),
                ),
                TextField(
                  controller: optionAController,
                  decoration: const InputDecoration(labelText: 'Option A'),
                ),
                TextField(
                  controller: optionBController,
                  decoration: const InputDecoration(labelText: 'Option B'),
                ),
                TextField(
                  controller: optionCController,
                  decoration: const InputDecoration(labelText: 'Option C'),
                ),
                TextField(
                  controller: optionDController,
                  decoration: const InputDecoration(labelText: 'Option D'),
                ),
                TextField(
                  controller: correctOptionController,
                  decoration:
                      const InputDecoration(labelText: 'Correct Option'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _questions.add({
                    'text': questionController.text,
                    'options': [
                      optionAController.text,
                      optionBController.text,
                      optionCController.text,
                      optionDController.text,
                    ],
                    'correctOption': correctOptionController.text,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createExam() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final examDoc =
            await FirebaseFirestore.instance.collection('Exams').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'createdBy': _getUserEmail(),
          'startTime': _startTimeController.text,
          'endTime': _endTimeController.text,
          'submissionLimit': int.tryParse(_submissionLimitController.text) ?? 1,
          'questions': _questions.map((q) => q['text']).toList(),
          'createdAt': Timestamp.now(),
        });

        for (var question in _questions) {
          await FirebaseFirestore.instance.collection('Questions').add({
            'examId': examDoc.id,
            ...question,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam created successfully!')),
        );

        _formKey.currentState?.reset();
        setState(() {
          _questions.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating exam: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      final selectedTime =
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      controller.text = DateFormat('HH:mm').format(selectedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(title: 'Create Exam'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep == 0) {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _currentStep += 1;
                    });
                  }
                } else {
                  _createExam();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() {
                    _currentStep -= 1;
                  });
                }
              },
              controlsBuilder: (context, ControlsDetails details) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Color.fromARGB(255, 179, 120, 224)),
                        ),
                        onPressed: details.onStepCancel,
                        child: const Text('Back' , style: TextStyle(color: Colors.white),),
                      ),
                      SizedBox(width: 1),
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(_currentStep == 1 ? 'Create Exam' : 'Next' , style: const TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                       backgroundColor: Color(0xFF7826B5),

                      ),
                    ),
                  ],
                );
              },
              steps: [
                Step(
                  title: const Text('Exam Details'),
                  content: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration:
                              const InputDecoration(labelText: 'Exam Title'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _descriptionController,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _startTimeController,
                          decoration:
                              const InputDecoration(labelText: 'Start Time'),
                          readOnly: true,
                          onTap: () =>
                              _selectTime(context, _startTimeController),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a start time';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _endTimeController,
                          decoration:
                              const InputDecoration(labelText: 'End Time'),
                          readOnly: true,
                          onTap: () =>
                              _selectTime(context, _endTimeController),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select an end time';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _submissionLimitController,
                          decoration: const InputDecoration(
                              labelText: 'Submission Limit'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a submission limit';
                            }
                            if (int.tryParse(value) == null ||
                                int.parse(value) <= 0) {
                              return 'Submission limit must be a positive number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  isActive: _currentStep >= 0,
                  state:
                      _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text('Add Questions'),
                  content: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _addQuestion,
                        child: const Text('Add Question'),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_questions[index]['text']),
                            subtitle: Text(
                                'Options: ${_questions[index]['options'].join(', ')}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    // Add your edit question logic here
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      _questions.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  isActive: _currentStep >= 1,
                  state:
                      _currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
              ],
            ),
    );
  }
}
