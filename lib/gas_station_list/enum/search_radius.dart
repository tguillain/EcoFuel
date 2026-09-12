enum SearchRadius {
  fiveKm(5),
  tenKm(10),
  twentyFiveKm(25),
  fiftyKm(50);

  const SearchRadius(this.inKm);

  final int inKm;

  String get label => '$inKm km';
}
