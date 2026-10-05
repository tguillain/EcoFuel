import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

class FreshnessNote extends StatelessWidget {
  const FreshnessNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        spacing: 10,
        children: [
          const Icon(
            Icons.schedule,
            size: 16,
            color: AppColors.onSurfaceSubtle,
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.onSurfaceSubtle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
