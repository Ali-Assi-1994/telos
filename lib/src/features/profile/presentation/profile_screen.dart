import 'package:flutter/material.dart';

/// Placeholder for the profile feature. Not yet part of the documented
/// feature list — needs its own data/domain layers before real content
/// is added here.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile tab')),
    );
  }
}
