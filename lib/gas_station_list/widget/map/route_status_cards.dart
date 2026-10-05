import 'package:flutter/material.dart';

/// Indique que l'itinéraire est en cours de calcul.
class RouteLoadingCard extends StatelessWidget {
  const RouteLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Calcul de l’itinéraire...'),
          ],
        ),
      ),
    );
  }
}

/// Message affiché si le calcul d'itinéraire échoue.
class RouteErrorCard extends StatelessWidget {
  const RouteErrorCard({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            IconButton(onPressed: onDismiss, icon: const Icon(Icons.close)),
          ],
        ),
      ),
    );
  }
}
