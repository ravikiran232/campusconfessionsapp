import 'package:flutter/material.dart';

class NewCard extends StatelessWidget {
  const NewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
      decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 1.5,
              spreadRadius: 1.0,
              offset: Offset(1.5, 1.0),
            ),
          ],
          gradient: LinearGradient(
              colors: [Color.fromARGB(209, 64, 195, 255), Colors.indigo],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight)),
      child: const Text(
        'NEW',
        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }
}
