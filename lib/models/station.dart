class Station {
  final String adresse;
  final String ville;
  final double? prix;

  Station({required this.adresse, required this.ville, this.prix});

  factory Station.fromJson(Map<String, dynamic> json) {
    // Récupération sécurisée du prix (E10 ou Gazole)
    dynamic prixBrut = json['e10_prix'] ?? json['gazole_prix'];
    double? prixFinal;
    if (prixBrut != null) {
      prixFinal = (prixBrut as num).toDouble();
    }

    return Station(
      adresse: json['adresse'] ?? 'Adresse inconnue',
      ville: json['ville'] ?? '',
      prix: prixFinal,
    );
  }
}
