class Station {
  final String adresse;
  final String ville;
  final Map<String, double?> prixCarburants;
  final double distanceKm;

  final bool automate2424;
  final String? horaires;
  final bool ferme;

  Station({
    required this.adresse,
    required this.ville,
    required this.prixCarburants,
    required this.distanceKm,
    required this.automate2424,
    this.horaires,
    required this.ferme,
  });

  double? getPrix(String carburant) {
    return prixCarburants[carburant];
  }

  factory Station.fromJson(Map<String, dynamic> json) {
    bool automateResult = false;
    bool fermeResult = false;
    String? horairesResult;

    // -------------------------
    // AUTOMATE 24/24
    // -------------------------
    final automate24 = json['horaires_automate_24_24']
        ?.toString()
        .toLowerCase();

    if (automate24 == 'oui') {
      automateResult = true;
    }

    // -------------------------
    // HORAIRES DU JOUR
    // -------------------------
    final horairesJour = json['horaires_jour']?.toString().trim();

    if (!automateResult && horairesJour != null && horairesJour.isNotEmpty) {
      const nomsJours = [
        'Lundi',
        'Mardi',
        'Mercredi',
        'Jeudi',
        'Vendredi',
        'Samedi',
        'Dimanche',
      ];

      final jourActuel = nomsJours[DateTime.now().weekday - 1];

      final jours = horairesJour.split(',');

      String? plageHoraire;

      for (final jour in jours) {
        final texte = jour.trim();

        if (texte.startsWith(jourActuel)) {
          plageHoraire = texte.replaceFirst(jourActuel, '').trim();
          break;
        }
      }

      if (plageHoraire != null && plageHoraire.contains('-')) {
        final parties = plageHoraire.split('-');

        if (parties.length == 2) {
          final ouverture = parties[0].trim();
          final fermeture = parties[1].trim();

          horairesResult = "jusqu'à ${fermeture.replaceAll('.', 'h')}";

          try {
            final maintenant = DateTime.now();

            final fermetureParts = fermeture.split('.');

            final heureFermeture = int.parse(fermetureParts[0]);

            final minuteFermeture = int.parse(fermetureParts[1]);

            final fermetureDate = DateTime(
              maintenant.year,
              maintenant.month,
              maintenant.day,
              heureFermeture,
              minuteFermeture,
            );

            if (maintenant.isAfter(fermetureDate)) {
              fermeResult = true;
              horairesResult = null;
            }
          } catch (_) {}
        }
      }
    }

    return Station(
      adresse: json['adresse']?.toString() ?? 'Adresse inconnue',

      ville: json['ville']?.toString() ?? 'Ville inconnue',

      distanceKm: (_toDouble(json['distance_m']) ?? 0) / 1000,

      automate2424: automateResult,
      horaires: horairesResult,
      ferme: fermeResult,

      prixCarburants: {
        'Gazole': _toDouble(json['gazole_prix']),
        'SP95': _toDouble(json['sp95_prix']),
        'SP98': _toDouble(json['sp98_prix']),
        'E10': _toDouble(json['e10_prix']),
        'E85': _toDouble(json['e85_prix']),
        'GPLc': _toDouble(json['gplc_prix']),
      },
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '.'));
  }
}
