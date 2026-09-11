enum FuelType {
  diesel('Gazole', 'gazole_prix'),
  sp95('SP95', 'sp95_prix'),
  sp98('SP98', 'sp98_prix'),
  e10('E10', 'e10_prix');

  const FuelType(this.label, this.priceJsonKey);

  final String label;
  final String priceJsonKey;
}
