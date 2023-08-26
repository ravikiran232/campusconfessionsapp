import 'package:flutter/material.dart';

class CustomIconTextButton extends StatefulWidget {
  IconData icon;
  String text;
  VoidCallback onPressed;
  CustomIconTextButton(
      {super.key,
      required this.icon,
      required this.text,
      required this.onPressed});

  @override
  State<CustomIconTextButton> createState() => _CustomIconTextButtonState();
}

class _CustomIconTextButtonState extends State<CustomIconTextButton> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: widget.onPressed,
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(Colors.black),
        overlayColor: MaterialStateProperty.all(
          const Color.fromARGB(255, 220, 220, 220),
        ),
        //padding: MaterialStateProperty.all(EdgeInsets.zero),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7.0),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 25.0,
              color: const Color.fromARGB(255, 61, 61, 61),
            ),
            const SizedBox(
              width: 5.0,
            ),
            Text(
              widget.text,
              // style: GoogleFonts.secularOne(
              //     textStyle: const TextStyle(
              //         fontSize: 21.0, fontWeight: FontWeight.w100)),
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05,
                fontWeight: FontWeight.w500,
                color: const Color.fromARGB(255, 61, 61, 61),
              ),
            )
          ],
        ),
      ),
    );
  }
}
