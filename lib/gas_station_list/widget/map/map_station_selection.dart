import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/effective_price.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/widget/map/station_marker_color.dart';
import 'package:flutter/material.dart';

/// Une station placée sur la carte, avec la couleur de son marqueur.
typedef MapMarkerEntry = ({GasStation station, Color color});

/// Choisit les stations à placer sur la carte parmi celles du rayon.
class MapStationSelection {
  const MapStationSelection({
    required this.stations,
    required this.fuel,
    required this.limit,
    this.routeDestination,
  });

  final List<GasStation> stations;
  final FuelType fuel;

  /// Nombre maximal de stations retenues : au-delà, la carte devient
  /// illisible.
  final int limit;

  /// Destination de l'itinéraire en cours, à garder affichée.
  final GasStation? routeDestination;

  /// Stations qui ont des coordonnées et un prix pour le carburant choisi.
  List<GasStation> get _located {
    return stations
        .where(
          (station) =>
              station.latitude != 0 &&
              station.longitude != 0 &&
              station.priceFor(fuel) != null,
        )
        .toList();
  }

  /// Les meilleures stations, prix et distance confondus, au plus [limit]. La
  /// destination d'un itinéraire reste affichée même hors de ce classement :
  /// la route mènerait sinon vers un point vide.
  List<GasStation> get visible {
    final List<GasStation> best = EffectivePrice.best(
      _located,
      fuel: fuel,
      count: limit,
    );

    final GasStation? destination = routeDestination;

    if (destination == null ||
        best.any((station) => station.id == destination.id)) {
      return best;
    }

    return [...best, destination];
  }

  /// Stations visibles et leur couleur, de la plus chère à la moins chère.
  ///
  /// L'ordre de la liste est l'ordre de dessin : les
  /// meilleurs prix passent ainsi au-dessus des autres.
  List<MapMarkerEntry> get markerEntries {
    final List<GasStation> shown = visible;

    final List<MapMarkerEntry> entries = shown
        .map(
          (station) => (
            station: station,
            color: StationMarkerColor.forStation(
              station: station,
              stations: shown,
              fuel: fuel,
            ),
          ),
        )
        .toList();

    entries.sort((a, b) => _priceOf(b.station).compareTo(_priceOf(a.station)));

    return entries;
  }

  /// La moins chère du rayon, que sa fiche signale. Elle peut manquer aux
  /// meilleures si elle est loin : la fiche d'une autre ne doit pas alors
  /// prétendre au titre.
  GasStation? get cheapest {
    final List<GasStation> located = _located;

    if (located.isEmpty) {
      return null;
    }

    return located.reduce(
      (cheapest, station) =>
          _priceOf(station) < _priceOf(cheapest) ? station : cheapest,
    );
  }

  /// Prix de la station pour le carburant choisi. Une station sans prix passe
  /// pour la plus chère, donc sous les autres marqueurs.
  double _priceOf(GasStation station) =>
      station.priceFor(fuel) ?? double.infinity;
}
