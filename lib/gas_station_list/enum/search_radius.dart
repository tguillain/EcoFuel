enum SearchRadius {
  fiveKm(5, mapStationLimit: 10),
  tenKm(10, mapStationLimit: 10),
  twentyFiveKm(25, mapStationLimit: 15),
  fiftyKm(50, mapStationLimit: 20);

  const SearchRadius(this.inKm, {required this.mapStationLimit});

  final int inKm;

  /// Nombre de stations placées sur la carte : un grand rayon couvre plus de
  /// communes et mérite plus de marqueurs, mais au-delà la carte devient
  /// illisible.
  final int mapStationLimit;

  String get label => '$inKm km';
}
