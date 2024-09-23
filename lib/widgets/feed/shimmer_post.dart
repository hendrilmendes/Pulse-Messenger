import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget buildShimmerPost() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Imagem ou Vídeo Placeholder
        Container(
          height: 250, // Altura para imagem ou vídeo
          color: Colors.grey[300],
        ),

        // Conteúdo do post
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 14,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 4),
              Container(
                width: 150,
                height: 14,
                color: Colors.grey[300],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
