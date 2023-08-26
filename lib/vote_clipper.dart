import 'package:flutter/material.dart';

class VoteClipper extends StatelessWidget {
  Color color;
  double icon_height;
  double icon_width;
  VoteClipper({
    super.key,
    this.color = Colors.orange,
    this.icon_height = 15.0,
    this.icon_width = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CustomShape(),
      child: Container(
        color: this.color,
        height: icon_height,
        width: icon_width,
        child: const Text(''),
      ),
    );
  }
}

class _CustomShape extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    Path path = Path();

    path.lineTo(size.width * 0.5, 0.0);
    path.lineTo(0, size.height * 0.6);
    path.lineTo(size.width * 0.3, size.height * 0.6);
    path.lineTo(size.width * 0.3, size.height);
    path.lineTo(size.width * 0.7, size.height);
    path.lineTo(size.width * 0.7, size.height * 0.6);
    path.lineTo(size.width, size.height * 0.6);
    path.lineTo(size.width * 0.5, 0.0);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return true;
  }
}
