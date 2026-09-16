import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';

class GasStation {
  const GasStation({
    required this.id,
    required this.address,
    required this.city,
    required this.pricesByFuel,
    required this.distanceInKm,
    required this.latitude,
    required this.longitude,
    required this.isOpen24h,
    required this.closingTime,
    required this.isClosed,
    this.brand,
  });

  final String id;
  final String address;
  final String city;
  final Map<FuelType, double?> pricesByFuel;
  final double distanceInKm;

  /// Position de la station. Requise : la carte, le calcul d'itinéraire et le
  /// regroupement des points de distribution en dépendent tous.
  final double latitude;
  final double longitude;

  /// Automate accessible 24h/24 : la station n'a alors pas d'horaire de fermeture.
  final bool isOpen24h;

  /// Heure de fermeture du jour, formatée pour l'affichage (ex. `20h30`).
  /// `null` si l'horaire est inconnu ou si la station est déjà fermée.
  final String? closingTime;

  final bool isClosed;

  /// Enseigne (Total, Intermarché…), absente du fichier de l'État : elle vient
  /// d'une source tierce et peut ne pas être connue.
  final String? brand;

  double? priceFor(FuelType fuel) => pricesByFuel[fuel];

  /// L'enseigne ne peut être résolue qu'une fois la position connue, donc
  /// après la construction : ce copieur évite de relire le JSON.
  GasStation withBrand(String? brand) => GasStation(
    id: id,
    address: address,
    city: city,
    pricesByFuel: pricesByFuel,
    distanceInKm: distanceInKm,
    latitude: latitude,
    longitude: longitude,
    isOpen24h: isOpen24h,
    closingTime: closingTime,
    isClosed: isClosed,
    brand: brand,
  );

  /// `null` quand la géométrie manque : mieux vaut écarter la station que lui
  /// inventer une position, qui la placerait au large du golfe de Guinée.
  ///
  /// [now] n'existe que pour rendre l'interprétation des horaires testable ;
  /// en production l'heure courante suffit.
  static GasStation? fromJson(Map<String, dynamic> json, {DateTime? now}) {
    final coordinates = _coordinatesOf(json);

    if (coordinates == null) {
      return null;
    }

    final address = json['adresse']?.toString() ?? 'Adresse inconnue';
    final city = json['ville']?.toString() ?? 'Ville inconnue';
    final openingHours = _OpeningHours.fromJson(json, now ?? DateTime.now());

    return GasStation(
      id: json['id']?.toString() ?? '$address-$city',
      address: address,
      city: city,
      distanceInKm: (_toDouble(json['distance_m']) ?? 0) / 1000,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      isOpen24h: openingHours.isOpen24h,
      closingTime: openingHours.closingTime,
      isClosed: openingHours.isClosed,
      pricesByFuel: {
        for (final fuel in FuelType.values)
          fuel: _toDouble(json[fuel.priceJsonKey]),
      },
    );
  }

  /// L'API expose `geom` sous forme d'objet `{lat, lon}` ; la forme GeoJSON
  /// `{coordinates: [lon, lat]}` est acceptée au cas où elle réapparaîtrait.
  static ({double latitude, double longitude})? _coordinatesOf(
    Map<String, dynamic> json,
  ) {
    final geom = json['geom'];

    if (geom is! Map) {
      return null;
    }

    final latitude = _toDouble(geom['lat']);
    final longitude = _toDouble(geom['lon']);

    if (latitude != null && longitude != null) {
      return (latitude: latitude, longitude: longitude);
    }

    final coordinates = geom['coordinates'];

    if (coordinates is List && coordinates.length >= 2) {
      final geoJsonLongitude = _toDouble(coordinates[0]);
      final geoJsonLatitude = _toDouble(coordinates[1]);

      if (geoJsonLatitude != null && geoJsonLongitude != null) {
        return (latitude: geoJsonLatitude, longitude: geoJsonLongitude);
      }
    }

    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '.'));
  }
}


class _OpeningHours {
  const _OpeningHours({
    required this.isOpen24h,
    required this.closingTime,
    required this.isClosed,
  });

  const _OpeningHours.unknown()
      : isOpen24h = false,
        closingTime = null,
        isClosed = false;

  final bool isOpen24h;
  final String? closingTime;
  final bool isClosed;

  static const List<String> _dayNames = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  factory _OpeningHours.fromJson(
    Map<String, dynamic> json,
    DateTime now,
  ) {
    final automate =
        json['horaires_automate_24_24']
            ?.toString()
            .toLowerCase();

    if (automate == 'oui') {
      return const _OpeningHours(
        isOpen24h: true,
        closingTime: null,
        isClosed: false,
      );
    }

    final closingTime =
        _todayClosingTime(
      json['horaires_jour']
          ?.toString(),
      now,
    );

    if (closingTime == null) {
      return const _OpeningHours.unknown();
    }

    if (_isPast(
      closingTime,
      now,
    )) {
      return const _OpeningHours(
        isOpen24h: false,
        closingTime: null,
        isClosed: true,
      );
    }

    return _OpeningHours(
      isOpen24h: false,
      closingTime:
          '${closingTime.hour}h'
          '${_twoDigits(closingTime.minute)}',
      isClosed: false,
    );
  }

  static ({
    int hour,
    int minute,
  })? _todayClosingTime(
    String? dailyHours,
    DateTime now,
  ) {
    final hours = dailyHours?.trim();

    if (hours == null ||
        hours.isEmpty) {
      return null;
    }

    final today =
        _dayNames[now.weekday - 1];

    for (final entry
        in hours.split(',')) {
      final text = entry.trim();

      if (!text.startsWith(today)) {
        continue;
      }

      final range = text
          .replaceFirst(today, '')
          .trim()
          .split('-');

      if (range.length != 2) {
        return null;
      }

      return _parseTime(
        range[1].trim(),
      );
    }

    return null;
  }

  static ({
    int hour,
    int minute,
  })? _parseTime(
    String time,
  ) {
    final parts = time.split('.');

    if (parts.length != 2) {
      return null;
    }

    final hour =
        int.tryParse(parts[0]);

    final minute =
        int.tryParse(parts[1]);

    if (hour == null ||
        minute == null) {
      return null;
    }

    return (
      hour: hour,
      minute: minute,
    );
  }

  static bool _isPast(
    ({
      int hour,
      int minute,
    }) time,
    DateTime now,
  ) {
    return now.isAfter(
      DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      ),
    );
  }

  static String _twoDigits(
    int value,
  ) {
    return value
        .toString()
        .padLeft(2, '0');
  }
}