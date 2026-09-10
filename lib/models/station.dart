class Station {
  final String adresse;
  final String ville;

  final Map<String, double?> prixCarburants;

  final double distanceKm;

  Station({
    required this.adresse,
    required this.ville,
    required this.prixCarburants,
    required this.distanceKm,
  });

  double? getPrix(String carburant) {
    return prixCarburants[carburant];
  }

  factory Station.fromJson(Map<String, dynamic> json) {//transforme les données JSON en objet flutter
    return Station(
      adresse:
          json['adresse']?.toString() ??
          'Adresse inconnue',

      ville:
          json['ville']?.toString() ??
          'Ville inconnue',

      distanceKm:
          (_toDouble(json['distance_m']) ?? 0) /
          1000,

      prixCarburants: {
        'Gazole':
            _toDouble(json['gazole_prix']),

        'SP95':
            _toDouble(json['sp95_prix']),

        'SP98':
            _toDouble(json['sp98_prix']),

        'E10':
            _toDouble(json['e10_prix']),

        'E85':
            _toDouble(json['e85_prix']),

        'GPLc':
            _toDouble(json['gplc_prix']),
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

    return double.tryParse(
      value.toString().replaceAll(',', '.'),
    );
  }
}