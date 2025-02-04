//called from home

import 'package:flutter/material.dart';

class HeadingWithArrow extends StatelessWidget {
  final String headingText;
  final VoidCallback onArrowClick;

  const HeadingWithArrow({
    Key? key,
    required this.headingText,
    required this.onArrowClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            headingText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: onArrowClick,
            child: Icon(
              Icons.arrow_forward,
              size: 24.0,
            ),
          ),
        ],
      ),
    );
  }
}
