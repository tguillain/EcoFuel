import 'package:ecofuel/favorites/service/favorite_stations_store.dart';
import 'package:flutter/foundation.dart';

/// Les stations mises en favori, partagées par la liste, la carte et l'écran
/// des favoris : une étoile touchée quelque part se reflète partout.
class FavoriteStations extends ChangeNotifier {
  FavoriteStations(this._store);

  final FavoriteStationsStore _store;

  Set<String> _ids = {};

  Set<String> get ids => Set.unmodifiable(_ids);

  bool contains(String stationId) => _ids.contains(stationId);

  /// Un échec de lecture laisse la liste vide plutôt que de bloquer l'écran :
  /// les favoris sont un confort, pas une condition pour voir les prix.
  Future<void> load() async {
    try {
      _ids = await _store.load();
    } catch (error) {
      debugPrint('Favoris illisibles : $error');
    }

    notifyListeners();
  }

  Future<void> toggle(String stationId) async {
    _ids = _ids.contains(stationId)
        ? (_ids.toSet()..remove(stationId))
        : {..._ids, stationId};

    notifyListeners();

    await _store.save(_ids);
  }
}
