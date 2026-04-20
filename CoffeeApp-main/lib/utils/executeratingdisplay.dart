import 'package:flutter/material.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';

class Executeratingdisplay extends StatefulWidget {
  final double rate;
  final double? itemSize;
  const Executeratingdisplay({super.key, required this.rate, this.itemSize});

  @override
  State<Executeratingdisplay> createState() => _ExecuteratingdisplayState();
}

class _ExecuteratingdisplayState extends State<Executeratingdisplay> {
  @override
  Widget build(BuildContext context) {
    return RatingStars(
      axis: Axis.horizontal,
      value: widget.rate,
      starCount: 5,
      starSize: widget.itemSize ?? 20,
      starSpacing: 2,
      maxValueVisibility: true,
      valueLabelVisibility: false,
      animationDuration: Duration(milliseconds: 1000),


      starOffColor: const Color(0xffe7e8ea),
      starColor: Colors.amberAccent,
      angle: 12,
    );
  }
}




