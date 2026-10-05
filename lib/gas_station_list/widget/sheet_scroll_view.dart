import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Défilement de la feuille des stations : sa poignée épinglée, puis son
/// contenu.
///
/// Le tiré-pour-rafraîchir remplace le bouton Actualiser de l'ancienne
/// AppBar : il doit rester atteignable même sans station à faire défiler.
class SheetScrollView extends StatelessWidget {
  const SheetScrollView({
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.handle,
    required this.content,
  });

  /// Contrôleur fourni par la feuille : c'est lui qui la fait glisser avant
  /// de faire défiler son contenu.
  final ScrollController controller;

  final Future<void> Function() onRefresh;

  /// Sliver de la poignée, épinglé en tête.
  final Widget handle;

  /// Sliver du contenu.
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      // Flutter ne fait défiler qu'au doigt par défaut : sur le web de bureau,
      // la feuille ne se tirerait pas à la souris.
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context)
            .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
        child: CustomScrollView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [handle, content],
        ),
      ),
    );
  }
}
