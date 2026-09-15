/// L'ordre de déclaration est celui d'affichage dans le sélecteur : E10 est le
/// carburant sélectionné par défaut, il ouvre donc la liste.
enum FuelType {
  e10('E10', 'e10_prix'),
  sp95('SP95', 'sp95_prix'),
  sp98('SP98', 'sp98_prix'),
  diesel('Gazole', 'gazole_prix');

  const FuelType(this.label, this.priceJsonKey);

  final String label;
  final String priceJsonKey;
}
