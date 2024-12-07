import 'package:flutter/material.dart';

class QuestionNavigator extends StatefulWidget {
  final List<Map<String, dynamic>> questions;

  QuestionNavigator({required this.questions});

  @override
  _QuestionNavigatorState createState() => _QuestionNavigatorState();
}

class _QuestionNavigatorState extends State<QuestionNavigator> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _goToNextPage() {
    if (_currentIndex < widget.questions.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Questions'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                final question = widget.questions[index];
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      question['text'],
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _goToPreviousPage,
                icon: Icon(Icons.arrow_left),
                iconSize: 40,
                color: _currentIndex > 0 ? Colors.blue : Colors.grey,
              ),
              IconButton(
                onPressed: _goToNextPage,
                icon: Icon(Icons.arrow_right),
                iconSize: 40,
                color: _currentIndex < widget.questions.length - 1
                    ? Colors.blue
                    : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
