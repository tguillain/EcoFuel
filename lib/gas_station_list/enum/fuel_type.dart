/// L'ordre de déclaration est celui d'affichage dans le sélecteur : E10 est le
/// carburant sélectionné par défaut, il ouvre donc la liste.
enum FuelType {
  e10('E10', 'e10_prix', 'e10_maj'),
  sp95('SP95', 'sp95_prix', 'sp95_maj'),
  sp98('SP98', 'sp98_prix', 'sp98_maj'),
  diesel('Gazole', 'gazole_prix', 'gazole_maj');

  const FuelType(this.label, this.priceJsonKey, this.updatedAtJsonKey);

  final String label;
  final String priceJsonKey;

  /// Date du dernier relevé de ce prix, au format ISO 8601.
  final String updatedAtJsonKey;
}
