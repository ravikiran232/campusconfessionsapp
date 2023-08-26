import 'package:flutter/material.dart';

class CustomVerticalDivider extends StatelessWidget {
  Color color;
  double width;
  double height;
  CustomVerticalDivider(
      {super.key,
      this.color = Colors.white,
      this.width = 1.0,
      this.height = 25.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        width: width,
        height: height,
        color: color,
      ),
    );
  }
}
