import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerSearchWidget extends StatelessWidget {
  const ShimmerSearchWidget({
    super.key,
    this.height,
    this.width,
    this.borderRadius = BorderRadius.zero,
  });

  final double? height;
  final double? width;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
