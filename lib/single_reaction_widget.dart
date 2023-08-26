import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SingleReactionWidget extends StatefulWidget {
  bool lottie;
  bool showLabel;
  String emoji;
  String emoji_path;
  String label;
  Color label_color;
  double lottie_scale;
  SingleReactionWidget({
    super.key,
    this.showLabel = true,
    this.emoji = '',
    this.emoji_path = '',
    this.lottie = false,
    required this.label,
    this.label_color = Colors.black,
    this.lottie_scale = 1.0,
  });

  @override
  State<SingleReactionWidget> createState() => _SingleReactionWidgetState();
}

class _SingleReactionWidgetState extends State<SingleReactionWidget> {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.showLabel ? EdgeInsets.symmetric(
        horizontal: widget.label == 'like' ? MediaQuery.of(context).size.width * 0.038 : widget.label == 'love' ? MediaQuery.of(context).size.width * 0.03 : widget.label == 'haha' ? MediaQuery.of(context).size.width * 0.018
        : widget.label == 'wink' ? MediaQuery.of(context).size.width * 0.022 : widget.label == 'woah' ? MediaQuery.of(context).size.width * 0.013
        : widget.label == 'sad' ? MediaQuery.of(context).size.width * 0.0335 : widget.label == 'angry' ? MediaQuery.of(context).size.width * 0.01 : 10.0 
      ) : widget.label == 'like' ? const EdgeInsets.only(right: 0.0) : EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.01),
      child: Row(
        children: [
          widget.lottie
              ? Transform.scale(
                  scale: widget.lottie_scale,
                  child: Lottie.asset(
                    widget.emoji_path,
                    animate: false,
                    height: MediaQuery.of(context).size.width * 0.07,
                    fit: BoxFit.cover,
                  ),
                )
              : Text(
                  widget.emoji,
                  style: widget.showLabel ? TextStyle(
                    fontSize: widget.label == 'love' ? MediaQuery.of(context).size.width * 0.053 : 
                    widget.label == 'haha' || widget.label == 'wink' || widget.label == 'woah' || widget.label == 'sad' || widget.label == 'angry' ? MediaQuery.of(context).size.width * 0.057 : 17.0
                  ) : TextStyle(
                    fontSize: widget.label == 'love' ? MediaQuery.of(context).size.width * 0.04 : 
                    widget.label == 'haha' || widget.label == 'wink' || widget.label == 'woah' || widget.label == 'sad' || widget.label == 'angry' ? MediaQuery.of(context).size.width * 0.04 : 17.0
                  ),
                ),
          widget.showLabel
              ? const SizedBox(
                  width: 5.0,
                )
              : Container(),
          widget.showLabel
              ? Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 21.5,
                    fontWeight: FontWeight.w400,
                    color: widget.label_color,
                  ),
                )
              : Container(),
        ],
      ),
    );
    ;
  }
}
