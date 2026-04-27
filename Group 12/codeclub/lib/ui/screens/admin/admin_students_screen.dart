import 'package:flutter/material.dart';

/// Legacy students screen kept for compatibility.
class AdminStudentsScreen extends StatelessWidget {
  const AdminStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Student admin list is not available in this build.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
