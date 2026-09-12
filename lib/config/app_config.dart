/// Configuration injectée à la compilation via `--dart-define`.
///
/// Ne contient que des valeurs publiques : aucune clé ni secret ne doit être
/// ajouté ici, un `--dart-define` restant extractible du binaire livré.
abstract final class AppConfig {
  static const String _latitudeKey = 'FIXED_LATITUDE';
  static const String _longitudeKey = 'FIXED_LONGITUDE';

  static const String rawFixedLatitude = String.fromEnvironment(_latitudeKey);
  static const String rawFixedLongitude = String.fromEnvironment(_longitudeKey);

  /// Vrai dès qu'une des deux coordonnées est fournie : fournir la seule
  /// latitude est une erreur de frappe, pas une demande d'utiliser le GPS.
  static const bool hasFixedLocation =
      bool.hasEnvironment(_latitudeKey) || bool.hasEnvironment(_longitudeKey);

  static double? get fixedLatitude => double.tryParse(rawFixedLatitude);

  static double? get fixedLongitude => double.tryParse(rawFixedLongitude);
}
