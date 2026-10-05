import 'package:ecofuel/gas_station_list/service/user_locator.dart';

/// Lieu autour duquel chercher les stations, à la place de la position de
/// l'utilisateur : une commune, une adresse, un lieu-dit.
class SearchPlace {
  const SearchPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.context,
  });

  /// Ce que l'en-tête affiche : « Lyon », « 12 rue de la Paix 75002 Paris ».
  final String name;

  /// Département et région, pour distinguer deux communes homonymes.
  final String? context;

  final double latitude;
  final double longitude;

  UserCoordinates get coordinates =>
      UserCoordinates(latitude: latitude, longitude: longitude);

  /// `null` quand la réponse n'a pas de point exploitable.
  static SearchPlace? fromFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'];
    final properties = feature['properties'];

    if (geometry is! Map || properties is! Map) {
      return null;
    }

    final coordinates = geometry['coordinates'];
    final name = properties['label']?.toString();

    if (coordinates is! List || coordinates.length < 2 || name == null) {
      return null;
    }

    final longitude = coordinates[0];
    final latitude = coordinates[1];

    if (longitude is! num || latitude is! num) {
      return null;
    }

    return SearchPlace(
      name: name,
      context: properties['context']?.toString(),
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
    );
  }
}
