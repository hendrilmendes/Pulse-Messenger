 import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget buildShimmerStory() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 12,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }