import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController _quizDateController = TextEditingController();
  final List<Map<String, dynamic>> _questions = [];

  final TextEditingController pointController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  bool _isLoading = false;
  int _currentStep = 0;
  bool _randomization = false;

  String questionType = 'MCQ'; // Default type
  final TextEditingController questionController = TextEditingController();
  final TextEditingController optionAController = TextEditingController();
  final TextEditingController optionBController = TextEditingController();
  final TextEditingController optionCController = TextEditingController();
  final TextEditingController optionDController = TextEditingController();
  final TextEditingController correctOptionController = TextEditingController();
  bool isTrue = true;
  bool showForm = false;
  String? _classId;

  String? _getUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email;
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
          'quizDate': _quizDateController.text,
          'createdAt': Timestamp.now(),
          'class': _classId,
          'randomization': _randomization,
        });

        List<String> questionIds = [];
        for (var question in _questions) {
          await FirebaseFirestore.instance.collection('Questions').add({
            'examId': examDoc.id,
            ...question,
          });
          questionIds.add(question['id']);
        }

        // Update the exam document with the question IDs
        await FirebaseFirestore.instance
            .collection('Exams')
            .doc(examDoc.id)
            .update({
          'questions': questionIds,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Quiz created successfully!'),
              backgroundColor: Colors.green),
        );

        _formKey.currentState?.reset();
        setState(() {
          _questions.clear();
        });
          Navigator.pushReplacementNamed(context, '/homeAdmin');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error creating exam: $e'),
              backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editQuestion(int index) {
    final question = _questions[index];
    questionController.text = question['text'];
    questionType = question['type'];
    if (questionType == 'MCQ') {
      optionAController.text = question['options'][0];
      optionBController.text = question['options'][1];
      optionCController.text = question['options'][2];
      optionDController.text = question['options'][3];
      correctOptionController.text = question['correctOption'];
    } else if (questionType == 'Text') {
      correctOptionController.text = question['correctOption'];
    } else if (questionType == 'True/False') {
      isTrue = question['correctOption'] == 'true';
    }
    setState(() {
      showForm = true;
    });
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
      // appBar: const AdminAppBar(title: 'Create Exam'),
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
                          backgroundColor: MaterialStateProperty.all(
                              Color.fromARGB(255, 179, 120, 224)),
                        ),
                        onPressed: details.onStepCancel,
                        child: const Text(
                          'Back',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    SizedBox(width: 1),
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF7826B5),
                      ),
                      child: Text(
                        _currentStep == 1 ? 'Create Exam' : 'Next',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
              steps: [
                Step(
                  title: const Text('Quiz Details'),
                  content: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          'Enter Quiz Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7826B5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Quiz Title',
                            prefixIcon:
                                Icon(Icons.title, color: Color(0xFF7826B5)),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.description,
                                color: Color(0xFF7826B5)),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _startTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            prefixIcon: Icon(
                              Icons.access_time,
                              color: Color(0xFF7826B5),
                            ),
                            border: OutlineInputBorder(),
                          ),
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _endTimeController,
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            prefixIcon: Icon(Icons.access_time,
                                color: Color(0xFF7826B5)),
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () => _selectTime(context, _endTimeController),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select an end time';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _submissionLimitController,
                          decoration: const InputDecoration(
                            labelText: 'attempts',
                            prefixIcon: Icon(Icons.format_list_numbered,
                                color: Color(0xFF7826B5)),
                            border: OutlineInputBorder(),
                          ),
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
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _quizDateController, // New field
                          decoration: const InputDecoration(
                            labelText: 'Quiz Date',
                            prefixIcon: Icon(Icons.calendar_today,
                                color: Color(0xFF7826B5)),
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              _quizDateController.text =
                                  DateFormat('yyyy-MM-dd').format(pickedDate);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a quiz date';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('classes')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            var classList = snapshot.data!.docs.map((doc) {
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(doc['name']),
                              );
                            }).toList();
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Class',
                                prefixIcon: Icon(Icons.class_,
                                    color: Color(0xFF7826B5)),
                                border: OutlineInputBorder(),
                              ),
                              items: classList,
                              onChanged: (value) {
                                setState(() {
                                  _classId = value!;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a class';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .shuffle, // Choose an appropriate icon
                                          color: Color(0xFF7826B5),
                                        ),
                                        SizedBox(
                                            width:
                                                8), // Add some space between the icon and text
                                        Text(
                                          'Randomize Questions',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF7826B5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        _randomization
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: _randomization
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      Switch(
                                        value: _randomization,
                                        onChanged: (value) {
                                          setState(() {
                                            _randomization = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text(_questions[index]['text']),
                              subtitle: Text(
                                'Type: ${_questions[index]['type']}, Options: ${_questions[index]['options']?.join(', ')}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      _editQuestion(index);
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
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildQuestionForm(),
                      const SizedBox(height: 20),
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

  Widget _buildQuestionForm() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(),
            const Text('Add Question :',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                borderRadius: BorderRadius.circular(8),
                dropdownColor: Colors.white,
                value: questionType,
                items: ['MCQ', 'Text', 'True/False'].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    questionType = value!;
                    showForm = true;
                  });
                },
                underline: const SizedBox(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Visibility(
          visible: showForm,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question Text',
                    prefixIcon: Icon(Icons.question_answer),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
               
                if (questionType == 'MCQ') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: optionAController,
                    decoration: const InputDecoration(
                      labelText: 'Option A',
                      prefixIcon: Icon(Icons.looks_one),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: optionBController,
                    decoration: const InputDecoration(
                      labelText: 'Option B',
                      prefixIcon: Icon(Icons.looks_two),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: optionCController,
                    decoration: const InputDecoration(
                      labelText: 'Option C',
                      prefixIcon: Icon(Icons.looks_3),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: optionDController,
                    decoration: const InputDecoration(
                      labelText: 'Option D',
                      prefixIcon: Icon(Icons.looks_4),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: correctOptionController,
                    decoration: const InputDecoration(
                      labelText: 'Correct Option',
                      prefixIcon: Icon(Icons.check),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (questionType == 'Text') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: correctOptionController,
                    decoration: const InputDecoration(
                      labelText: 'Answer Text',
                      prefixIcon: Icon(Icons.text_fields),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (questionType == 'True/False') ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Is the answer True?'),
                    value: isTrue,
                    onChanged: (value) {
                      setState(() {
                        isTrue = value;
                      });
                    },
                  ),
                ],
                 const SizedBox(height: 16),
                  TextField(
                  controller: pointController,
                  decoration: const InputDecoration(
                    labelText: 'Points',
                    prefixIcon: Icon(Icons.score),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    prefixIcon: Icon(Icons.image),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showForm = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _questions.add({
                            'id': UniqueKey().toString(),
                            'text': questionController.text,
                            'type': questionType,
                            'points': int.tryParse(pointController.text) ?? 0,
                            'imageUrl': imageUrlController.text,
                            'options': questionType == 'MCQ'
                                ? [
                                    optionAController.text,
                                    optionBController.text,
                                    optionCController.text,
                                    optionDController.text
                                  ]
                                : null,
                            'correctOption': questionType == 'MCQ'
                                ? correctOptionController.text
                                : (questionType == 'True/False'
                                    ? isTrue.toString()
                                    : correctOptionController.text),
                          });
                          showForm = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Save Question',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
