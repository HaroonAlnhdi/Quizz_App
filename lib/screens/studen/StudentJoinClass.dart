import 'package:flutter/material.dart';

class StudentJoinClass extends StatelessWidget {
  final Future<void> Function(String) onJoinClass;

  const StudentJoinClass({
    Key? key,
    required this.onJoinClass,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        String? classCode = await showDialog<String>(
          context: context,
          builder: (context) {
            TextEditingController controller = TextEditingController();
            return AlertDialog(
              title: const Text('Join Class'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter class code',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: const Text('Join'),
                ),
              ],
            );
          },
        );

        if (classCode != null && classCode.isNotEmpty) {
          await onJoinClass(classCode);
        }
      },
      child: const Icon(Icons.add),
      backgroundColor: Colors.purple,
    );
  }
}
