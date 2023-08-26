import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class RankClipper extends StatelessWidget {
  Color color1;
  Color color2;
  String text;
  RankClipper({
    super.key,
    this.color1 = Colors.orange,
    this.color2 = Colors.red,
    this.text = '',
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CustomShape(),
      child: SizedBox(
        width: 30.0,
        height: 50.0,
        child: Container(
          padding: const EdgeInsets.only(
            top: 8.0,
            left: 8.0,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [color1, color2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            // boxShadow: const [
            //   BoxShadow(
            //       color: Color.fromARGB(255, 255, 255, 255),
            //       spreadRadius: 10.0,
            //       blurRadius: 15.0)
            // ]
            //Solve this problem!!! Need elevation for the clipper.
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.white,
            highlightColor: Colors.grey,
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomShape extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    Path path = Path();

    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.5, size.height * 0.8);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return true;
  }
}
