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
  });

  final String id;
  final String address;
  final String city;

  final Map<FuelType, double?> pricesByFuel;

  final double distanceInKm;

  final double latitude;
  final double longitude;

  final bool isOpen24h;
  final String? closingTime;
  final bool isClosed;

  double? priceFor(FuelType fuel) {
    return pricesByFuel[fuel];
  }

  factory GasStation.fromJson(
    Map<String, dynamic> json, {
    DateTime? now,
  }) {
    final address =
        json['adresse']?.toString() ??
        'Adresse inconnue';

    final city =
        json['ville']?.toString() ??
        'Ville inconnue';

    final openingHours =
        _OpeningHours.fromJson(
      json,
      now ?? DateTime.now(),
    );

    final coordinates =
        _extractCoordinates(json);

    return GasStation(
      id:
          json['id']?.toString() ??
          '$address-$city',
      address: address,
      city: city,
      distanceInKm:
          (_toDouble(json['distance_m']) ?? 0) /
          1000,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      isOpen24h:
          openingHours.isOpen24h,
      closingTime:
          openingHours.closingTime,
      isClosed:
          openingHours.isClosed,
      pricesByFuel: {
        for (final fuel in FuelType.values)
          fuel: _toDouble(
            json[fuel.priceJsonKey],
          ),
      },
    );
  }

  static ({
    double latitude,
    double longitude,
  }) _extractCoordinates(
    Map<String, dynamic> json,
  ) {
    final dynamic geom = json['geom'];

    if (geom is Map) {
      final latitude =
          _toDouble(geom['lat']);

      final longitude =
          _toDouble(geom['lon']);

      if (latitude != null &&
          longitude != null) {
        return (
          latitude: latitude,
          longitude: longitude,
        );
      }

      final dynamic coordinates =
          geom['coordinates'];

      if (coordinates is List &&
          coordinates.length >= 2) {
        final longitude =
            _toDouble(coordinates[0]);

        final latitude =
            _toDouble(coordinates[1]);

        if (latitude != null &&
            longitude != null) {
          return (
            latitude: latitude,
            longitude: longitude,
          );
        }
      }
    }

    return (
      latitude: 0,
      longitude: 0,
    );
  }

  static double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value
          .toString()
          .replaceAll(',', '.'),
    );
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