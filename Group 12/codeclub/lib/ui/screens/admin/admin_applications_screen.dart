import 'package:flutter/material.dart';

/// Legacy applications screen kept for compatibility.
class AdminApplicationsScreen extends StatelessWidget {
  final String? hackathonId;
  final String? hackathonTitle;

  const AdminApplicationsScreen({
    super.key,
    this.hackathonId,
    this.hackathonTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          hackathonTitle != null ? 'Applications: $hackathonTitle' : 'Applications',
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Applications are now collected via direct Google Form links.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
