import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MessageState extends StatelessWidget {
  const MessageState({
    super.key,
    required this.icon,
    required this.message,
    required this.onRetry,
    this.iconColor,
    this.isScrollable = false,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;
  final Color? iconColor;

  /// Un `RefreshIndicator` n'arme son geste que sur un enfant défilable :
  /// l'état vide doit donc défiler, même quand son contenu tient à l'écran.
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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

    if (!isScrollable) {
      return Center(child: content);
    }

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: content),
        ),
      ),
    );
  }
}
