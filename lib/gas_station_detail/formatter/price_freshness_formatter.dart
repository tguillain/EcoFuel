/// Dit depuis quand le prix affiché a été relevé : un prix vieux de trois
/// jours ne vaut pas un prix de ce matin, et la fiche doit le laisser voir.
abstract final class PriceFreshnessFormatter {
  static String format(DateTime updatedAt, {required DateTime now}) {
    final elapsed = now.difference(updatedAt);

    // Une horloge de téléphone en avance sur le serveur donnerait un relevé
    // « dans le futur » : il est alors tout frais.
    if (elapsed.inMinutes < 1) {
      return 'Relevé à l\'instant';
    }

    if (elapsed.inHours < 1) {
      return 'Relevé il y a ${elapsed.inMinutes} min';
    }

    if (elapsed.inDays < 1) {
      return 'Relevé il y a ${elapsed.inHours} h';
    }

    final days = elapsed.inDays;

    return 'Relevé il y a $days jour${days > 1 ? 's' : ''}';
  }
}
