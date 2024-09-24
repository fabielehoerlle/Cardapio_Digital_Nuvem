import 'package:flutter/material.dart';

class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: AspectRatio(
        aspectRatio: 16 / 9, // YouTube-like thumbnail
        child: Image.asset(
          'assets/placeholder.jpeg',
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
