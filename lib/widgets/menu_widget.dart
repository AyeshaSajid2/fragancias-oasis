//widget displayed just below the 1st header on home show content of menus ui differs from menu fetch screen

import 'package:flutter/material.dart';
import 'package:oasis_fragrances/utils/const.dart';

class MenuWidget extends StatelessWidget {
  final String menuName;
  final String menuImage;
  final VoidCallback onTap;

  const MenuWidget({
    super.key,
    required this.menuName,
    required this.menuImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.all(8.0),
        // Perfect square size
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Center content vertically
          crossAxisAlignment:
              CrossAxisAlignment.center, // Center content horizontally
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                menuImage,
                height: 80, // Adjusted for a cleaner fit
                width: 80, // Consistent image size
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image, size: 80);
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              menuName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
