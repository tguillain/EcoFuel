class GasStation {
  const GasStation({
    required this.id,
    required this.name,
    required this.priceInEuros,
    required this.distanceInKm,
    required this.openingHours,
  });

  final String id;
  final String name;
  final double priceInEuros;
  final double distanceInKm;
  final String? openingHours;
}
