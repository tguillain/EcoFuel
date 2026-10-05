import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

class RouteBar extends StatelessWidget {
  const RouteBar({super.key, required this.minutes, required this.onPressed});

  final int? minutes;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(
              minutes != null ? 'Itinéraire · $minutes min' : 'Itinéraire',
            ),
          ),
        ),
      ),
    );
  }
}
