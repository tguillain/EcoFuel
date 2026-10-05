/// Carburants publiés par le flux des prix de l'État.
///
/// L'ordre de déclaration est celui d'affichage, du plus au moins distribué :
/// le gazole, le SP98 et l'E10 se trouvent dans plus de deux stations sur
/// trois, l'E85 dans un peu plus d'un tiers, le SP95 dans un peu plus d'un
/// quart, le GPLc dans une sur sept. E10 est le carburant sélectionné par
/// défaut, il ouvre donc la liste.
enum FuelType {
  e10('E10', 'e10_prix', 'e10_maj'),
  sp98('SP98', 'sp98_prix', 'sp98_maj'),
  diesel('Gazole', 'gazole_prix', 'gazole_maj'),
  e85('E85', 'e85_prix', 'e85_maj'),
  sp95('SP95', 'sp95_prix', 'sp95_maj'),
  gplc('GPLc', 'gplc_prix', 'gplc_maj');

  const FuelType(this.label, this.priceJsonKey, this.updatedAtJsonKey);

  /// Les plus distribués, que la liste propose en accès direct.
  static const List<FuelType> popular = [e10, sp98, diesel];

  /// Les autres, que la liste range derrière un menu.
  static final List<FuelType> others = [
    for (final fuel in values)
      if (!popular.contains(fuel)) fuel,
  ];

  final String label;
  final String priceJsonKey;

  /// Date du dernier relevé de ce prix, au format ISO 8601.
  final String updatedAtJsonKey;

  bool get isPopular => popular.contains(this);
}
