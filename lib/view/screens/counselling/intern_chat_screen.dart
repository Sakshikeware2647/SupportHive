import 'package:flutter/material.dart';
import '../../../model/intern_model.dart';

class InternChatScreen extends StatelessWidget {
  final Intern intern;

  const InternChatScreen({super.key, required this.intern});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(intern.name)),
      body: const Center(
        child: Text("Chat UI here"),
      ),
    );
  }
}