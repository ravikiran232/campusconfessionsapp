import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PollCard extends StatelessWidget {
  const PollCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
      decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
            Color.fromARGB(255, 146, 26, 167),
            Color.fromARGB(255, 206, 84, 227),
          ], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.all(Radius.circular(3.0))),
      child: const Text(
        'Poll',
        style: TextStyle(
            fontWeight: FontWeight.w800, letterSpacing: 0.5, fontSize: 11.0),
      ),
    );
  }
}
