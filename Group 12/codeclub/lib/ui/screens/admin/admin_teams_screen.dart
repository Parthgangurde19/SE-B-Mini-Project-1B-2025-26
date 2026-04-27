import 'package:flutter/material.dart';

/// Legacy teams screen kept for compatibility.
class AdminTeamsScreen extends StatelessWidget {
  const AdminTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teams')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Team management was removed from the current Google Form flow.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
