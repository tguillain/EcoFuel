import 'package:shared_preferences/shared_preferences.dart';

/// Où les favoris sont gardés d'un lancement à l'autre.
abstract interface class FavoriteStationsStore {
  Future<Set<String>> load();

  Future<void> save(Set<String> stationIds);
}

/// Clés des préférences de l'application. Renommer une valeur renomme la clé
/// stockée : les favoris déjà enregistrés seraient perdus.
enum _PreferenceKey { favoriteStationIds }

/// Garde les identifiants des stations favorites dans les préférences de
/// l'appareil : quelques chaînes, rien de sensible.
class PreferencesFavoriteStationsStore implements FavoriteStationsStore {
  PreferencesFavoriteStationsStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<Set<String>> load() async {
    final List<String>? ids = await _preferences.getStringList(
      _PreferenceKey.favoriteStationIds.name,
    );

    return {...?ids};
  }

  @override
  Future<void> save(Set<String> stationIds) => _preferences.setStringList(
    _PreferenceKey.favoriteStationIds.name,
    stationIds.toList(),
  );
}
