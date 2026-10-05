import 'dart:async';

import 'package:flutter/widgets.dart';

/// Relance [onRefresh] à intervalle régulier tant que l'application est au
/// premier plan.
///
/// Une application en arrière-plan n'a personne pour lire l'écran : continuer
/// à interroger l'API y dépenserait batterie et données pour rien. Au retour
/// au premier plan, un rafraîchissement part aussitôt, les données ayant pu
/// vieillir entre-temps.
class LifecycleRefresher with WidgetsBindingObserver {
  LifecycleRefresher({required this.interval, required this.onRefresh});

  final Duration interval;
  final VoidCallback onRefresh;

  Timer? _timer;

  void start() {
    WidgetsBinding.instance.addObserver(this);

    _startTimer();
  }

  void dispose() {
    _timer?.cancel();

    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();

      onRefresh();

      return;
    }

    _timer?.cancel();

    _timer = null;
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(interval, (_) => onRefresh());
  }
}
