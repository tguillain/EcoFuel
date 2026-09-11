import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';

class GasStation {
  const GasStation({
    required this.id,
    required this.address,
    required this.city,
    required this.pricesByFuel,
    required this.distanceInKm,
    required this.isOpen24h,
    required this.closingTime,
    required this.isClosed,
  });

  final String id;
  final String address;
  final String city;
  final Map<FuelType, double?> pricesByFuel;
  final double distanceInKm;

  /// Automate accessible 24h/24 : la station n'a alors pas d'horaire de fermeture.
  final bool isOpen24h;

  /// Heure de fermeture du jour, formatée pour l'affichage (ex. `20h30`).
  /// `null` si l'horaire est inconnu ou si la station est déjà fermée.
  final String? closingTime;

  final bool isClosed;

  double? priceFor(FuelType fuel) => pricesByFuel[fuel];

  /// [now] n'existe que pour rendre l'interprétation des horaires testable ;
  /// en production l'heure courante suffit.
  factory GasStation.fromJson(Map<String, dynamic> json, {DateTime? now}) {
    final address = json['adresse']?.toString() ?? 'Adresse inconnue';
    final city = json['ville']?.toString() ?? 'Ville inconnue';
    final openingHours = _OpeningHours.fromJson(json, now ?? DateTime.now());

    return GasStation(
      id: json['id']?.toString() ?? '$address-$city',
      address: address,
      city: city,
      distanceInKm: (_toDouble(json['distance_m']) ?? 0) / 1000,
      isOpen24h: openingHours.isOpen24h,
      closingTime: openingHours.closingTime,
      isClosed: openingHours.isClosed,
      pricesByFuel: {
        for (final fuel in FuelType.values)
          fuel: _toDouble(json[fuel.priceJsonKey]),
      },
    );
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

/// Interprète les champs d'horaires du jeu de données data.economie.gouv.fr,
/// qui expose `horaires_jour` sous la forme `Lundi 07.30-20.00, Mardi ...`.
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

  factory _OpeningHours.fromJson(Map<String, dynamic> json, DateTime now) {
    final automate = json['horaires_automate_24_24']?.toString().toLowerCase();

    if (automate == 'oui') {
      return const _OpeningHours(
        isOpen24h: true,
        closingTime: null,
        isClosed: false,
      );
    }

    final closingTime = _todayClosingTime(
      json['horaires_jour']?.toString(),
      now,
    );

    if (closingTime == null) {
      return const _OpeningHours.unknown();
    }

    if (_isPast(closingTime, now)) {
      return const _OpeningHours(
        isOpen24h: false,
        closingTime: null,
        isClosed: true,
      );
    }

    return _OpeningHours(
      isOpen24h: false,
      closingTime: '${closingTime.hour}h${_twoDigits(closingTime.minute)}',
      isClosed: false,
    );
  }

  static ({int hour, int minute})? _todayClosingTime(
    String? dailyHours,
    DateTime now,
  ) {
    final hours = dailyHours?.trim();

    if (hours == null || hours.isEmpty) {
      return null;
    }

    final today = _dayNames[now.weekday - 1];

    for (final entry in hours.split(',')) {
      final text = entry.trim();

      if (!text.startsWith(today)) {
        continue;
      }

      final range = text.replaceFirst(today, '').trim().split('-');

      if (range.length != 2) {
        return null;
      }

      return _parseTime(range[1].trim());
    }

    return null;
  }

  static ({int hour, int minute})? _parseTime(String time) {
    final parts = time.split('.');

    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    return (hour: hour, minute: minute);
  }

  static bool _isPast(({int hour, int minute}) time, DateTime now) {
    return now.isAfter(
      DateTime(now.year, now.month, now.day, time.hour, time.minute),
    );
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
