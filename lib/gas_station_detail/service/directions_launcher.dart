import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre l'itinéraire vers une station dans Google Maps.
///
/// Google Maps guide déjà mieux qu'une route tracée dans l'application :
/// trafic, guidage vocal, recalcul en route. Le lien universel ouvre l'app
/// Google Maps quand elle est installée, le site sinon.
class DirectionsLauncher {
  const DirectionsLauncher();

  static Uri uriFor(GasStation station) =>
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${station.latitude},${station.longitude}',
        'travelmode': 'driving',
      });

  /// `false` quand aucune application n'a pu ouvrir le lien.
  Future<bool> open(GasStation station) =>
      launchUrl(uriFor(station), mode: LaunchMode.externalApplication);
}
