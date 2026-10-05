import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MessageState extends StatelessWidget {
  const MessageState({
    super.key,
    required this.icon,
    required this.message,
    required this.onRetry,
    this.iconColor,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 55, color: iconColor ?? AppColors.onSurfaceMuted),
          const SizedBox(height: 15),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );

    return Center(child: content);
  }
}
