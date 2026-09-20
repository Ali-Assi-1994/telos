import 'package:flutter/material.dart';

/// Placeholder for the timer feature. Not yet part of the documented
/// feature list — needs its own data/domain layers before real content
/// is added here.
class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timer')),
      body: const Center(child: Text('Timer tab')),
    );
  }
}
