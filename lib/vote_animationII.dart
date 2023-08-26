import 'package:flutter/material.dart';
import 'package:untitled2/vote_clipper.dart';

class VoteAnimationII extends StatefulWidget {
  Color color;
  bool isAnimating;
  double icon_height;
  double icon_width;
  VoteAnimationII({
    super.key,
    this.color = Colors.orange,
    this.isAnimating = false,
    this.icon_height = 15.0,
    this.icon_width = 15.0,
  });

  @override
  State<VoteAnimationII> createState() => _VoteAnimationIIState();
}

class _VoteAnimationIIState extends State<VoteAnimationII>
    with SingleTickerProviderStateMixin {
  AnimationController? _voteAnimationController;
  Animation<double>? _scale;

  @override
  void initState() {
    super.initState();
    _voteAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _voteAnimationController!, curve: Curves.bounceOut),
    );

    _startAnimation();
  }

  @override
  void dispose() {
    super.dispose();
    _voteAnimationController!.dispose();
  }

  void _startAnimation() {
    _voteAnimationController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      alignment: widget.color == Colors.red
          ? Alignment.topCenter
          : Alignment.bottomCenter,
      scale: _scale!,
      child: widget.color == Colors.red
          ? Transform.translate(
              offset: const Offset(0.0, -1.0),
              child: Transform.rotate(
                angle: 1.5707963267948966 * 2,
                child: VoteClipper(
                  color: Colors.red,
                  icon_height: widget.icon_height,
                  icon_width: widget.icon_width,
                ),
              ),
            )
          : VoteClipper(
              color: widget.color,
              icon_height: widget.icon_height,
              icon_width: widget.icon_width,
            ),
    );
  }
}
