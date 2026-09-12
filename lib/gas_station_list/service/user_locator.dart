import 'package:geolocator/geolocator.dart';

/// Position de l'utilisateur, volontairement découplée de `Position` du paquet
/// geolocator pour que la couche service reste testable sans plugin natif.
class UserCoordinates {
  const UserCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Source de la position de l'utilisateur. [GeolocatorUserLocator] interroge le
/// GPS ; [FixedUserLocator] permet de s'en passer en test et en développement.
abstract interface class UserLocator {
  Future<UserCoordinates> currentCoordinates();
}

/// Implémentation réelle : demande la permission puis interroge le GPS.
class GeolocatorUserLocator implements UserLocator {
  const GeolocatorUserLocator();

  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  @override
  Future<UserCoordinates> currentCoordinates() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('La localisation est désactivée.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('La permission GPS a été refusée.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('La permission GPS est définitivement refusée.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: _locationSettings,
    );

    return UserCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

/// Position figée : développer sur une machine sans GPS fiable (PC de bureau,
/// CI) et rendre les tests reproductibles.
class FixedUserLocator implements UserLocator {
  const FixedUserLocator(this.coordinates);

  final UserCoordinates coordinates;

  @override
  Future<UserCoordinates> currentCoordinates() async => coordinates;
}
