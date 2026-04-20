import 'package:flutter/material.dart';

class DashedDivider extends StatelessWidget {
  final double dashWidth;
  final double dashSpace;
  final double thickness;
  final Color color;
  final double? width;

  const DashedDivider({
    super.key,
    this.dashWidth = 5,
    this.dashSpace = 3,
    this.thickness = 1,
    this.color = Colors.grey,
    this.width,
  });

  @override
  Widget build(BuildContext context) {


    return SizedBox(
      width: width,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {


          final boxWidth = constraints.constrainWidth();
          final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
          
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: thickness,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
