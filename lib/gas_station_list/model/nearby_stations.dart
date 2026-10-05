import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/service/gas_station_service.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:ecofuel/place_search/model/search_place.dart';
import 'package:flutter/foundation.dart';

/// Les stations autour du centre de recherche, et l'état de leur chargement.
///
/// Le centre est le lieu cherché s'il y en a un, la position de l'utilisateur
/// sinon. Seuls le rayon et ce centre demandent un appel à l'API : carburant,
/// tri et marque se filtrent à l'affichage.
class NearbyStations extends ChangeNotifier {
  NearbyStations(this._service);

  final GasStationService _service;

  /// Stations telles que renvoyées par l'API.
  List<GasStation> stations = const [];

  /// Position réelle de l'utilisateur, même autour d'un lieu cherché : la
  /// carte y pose son repère et la fiche en part pour l'itinéraire.
  UserCoordinates? userCoordinates;

  SearchRadius radius = SearchRadius.fiveKm;

  /// Lieu cherché à la place de la position de l'utilisateur ; `null` autour
  /// de lui. Le rafraîchissement automatique y reste fixé.
  SearchPlace? place;

  bool isLoading = false;

  String? errorMessage;

  /// Heure du dernier chargement réussi.
  DateTime? lastUpdatedAt;

  bool _isDisposed = false;

  /// Charge la position puis les stations.
  ///
  /// Un rafraîchissement [silent] n'affiche ni indicateur ni erreur : il part
  /// tout seul chaque minute, et remplacer la liste par un tourniquet ou un
  /// message d'échec serait pire que garder les dernières données connues.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final UserCoordinates coordinates = await _service.currentCoordinates();

      final List<GasStation> loaded = await _service.fetchNearbyStations(
        radius: radius,
        coordinates: place?.coordinates ?? coordinates,
      );

      userCoordinates = coordinates;
      stations = loaded;
      lastUpdatedAt = DateTime.now();
      errorMessage = null;
    } catch (error) {
      // Un échec de fond ne doit rien casser à l'écran : la liste précédente
      // reste affichée jusqu'au prochain passage.
      if (!silent) {
        stations = const [];
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      if (!silent) {
        isLoading = false;
      }

      _notify();
    }
  }

  /// Change de rayon : la zone de recherche change, on recharge.
  Future<void> changeRadius(SearchRadius newRadius) async {
    if (newRadius == radius) {
      return;
    }

    radius = newRadius;

    await load();
  }

  /// Cherche autour de [newPlace], ou autour de l'utilisateur s'il est nul.
  Future<void> searchAround(SearchPlace? newPlace, {SearchRadius? newRadius}) {
    place = newPlace;
    radius = newRadius ?? radius;

    return load();
  }

  /// Une réponse arrivée après la fermeture de l'écran n'a plus personne à
  /// prévenir.
  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    super.dispose();
  }
}
