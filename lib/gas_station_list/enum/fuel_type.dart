enum FuelType {
  e10('E10'),
  sp95('SP95'),
  sp98('SP98'),
  diesel('Gazole');

  const FuelType(this.label);

  final String label;
}
