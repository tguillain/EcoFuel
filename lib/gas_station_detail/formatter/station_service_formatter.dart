import 'package:ecofuel/gas_station_list/model/gas_station.dart';

/// Réduit les services déclarés à l'État aux pastilles courtes de la fiche.
///
/// Le fichier de l'État en liste une vingtaine, souvent en double (lavage
/// manuel et automatique, deux sortes de boutique) : seuls ceux qui comptent
/// pour un automobiliste de passage sont retenus, une fois chacun.
abstract final class StationServiceFormatter {
  static const Map<String, String> _shortLabels = {
    'Station de gonflage': 'Gonflage',
    'Lavage automatique': 'Lavage',
    'Lavage manuel': 'Lavage',
    'Boutique alimentaire': 'Boutique',
    'Boutique non alimentaire': 'Boutique',
    'Toilettes publiques': 'Toilettes',
    'Restauration à emporter': 'Restauration',
    'Restauration sur place': 'Restauration',
    'Bornes électriques': 'Recharge électrique',
    'DAB (Distributeur automatique de billets)': 'DAB',
    'Wifi': 'Wifi',
  };

  static List<String> labelsFor(GasStation station) {
    final labels = <String>{
      // L'ouverture 24h/24 vient des horaires, pas de la liste des services.
      if (station.isOpen24h) '24/7',
      for (final service in station.services)
        if (_shortLabels[service] != null) _shortLabels[service]!,
    };

    return labels.toList();
  }
}
