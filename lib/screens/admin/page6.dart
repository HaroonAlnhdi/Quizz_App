import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz Page',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: QuizPage(),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({Key? key}) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // Example quiz data with correct answers
  final quizData = {
    'quizId': 'quiz_1',
    'title': 'Quiz Title 1',
    'questions': [
      {
        'question': 'What is the capital of France?',
        'answers': ['Paris', 'London', 'Berlin', 'Madrid'],
        'correctIndex': 0, // Correct answer is 'Paris'
      },
      {
        'question': 'What is 2 + 2?',
        'answers': ['3', '4', '5', '6'],
        'correctIndex': 1, // Correct answer is '4'
      },
      {
        'question': 'Which planet is known as the Red Planet?',
        'answers': ['Earth', 'Mars', 'Jupiter', 'Venus'],
        'correctIndex': 1, // Correct answer is 'Mars'
      },
      {
        'question': 'What is the largest ocean on Earth?',
        'answers': ['Atlantic', 'Indian', 'Arctic', 'Pacific'],
        'correctIndex': 3, // Correct answer is 'Pacific'
      },
    ],
  };

  // Map to store the user's selected answers
  final Map<int, int> selectedAnswers = {};

  @override
  Widget build(BuildContext context) {
    // Explicitly cast quizData['questions'] to List
    final questions = quizData['questions'] as List;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${quizData['quizId']}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${quizData['title']}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length, // Use length on List
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q${index + 1}: ${question['question']}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: List.generate(
                              question['answers']?.length ?? 0,
                                  (answerIndex) {
                                return RadioListTile<int>(
                                  title: Text(question['answers']![answerIndex]),
                                  value: answerIndex,
                                  groupValue: selectedAnswers[index],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedAnswers[index] = value!;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _showResults(context);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResults(BuildContext context) {
    // Explicitly cast quizData['questions'] to List
    final questions = quizData['questions'] as List;

    int correctAnswers = 0;

    for (int i = 0; i < questions.length; i++) { // Use length on List
      final question = questions[i];
      if (selectedAnswers[i] == question['correctIndex']) {
        correctAnswers++;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quiz Results'),
          content: Text(
              'You got $correctAnswers/${questions.length} correct!'), // Use length on List
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
