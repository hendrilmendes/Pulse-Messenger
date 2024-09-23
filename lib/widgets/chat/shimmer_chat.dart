import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerChatAvatar extends StatelessWidget {
  final double radius;

  const ShimmerChatAvatar({super.key, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
      ),
    );
  }
}
