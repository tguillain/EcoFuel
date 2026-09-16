/// Remet en forme les adresses du fichier de l'État, dont la casse est
/// irrégulière : « 205 ROUTE DE VANNES » y côtoie « 80 Boulevard des Pas
/// Enchantés ». L'usage typographique français veut le type de voie en
/// minuscules et le nom propre capitalisé.
abstract final class AddressFormatter {
  /// Types de voie, toujours en minuscules.
  static const Set<String> _streetTypes = {
    'allee',
    'allees',
    'avenue',
    'boulevard',
    'carrefour',
    'chaussee',
    'chemin',
    'cite',
    'clos',
    'corniche',
    'cours',
    'domaine',
    'esplanade',
    'faubourg',
    'hameau',
    'impasse',
    'mail',
    'montee',
    'parc',
    'parvis',
    'passage',
    'place',
    'placette',
    'pont',
    'port',
    'promenade',
    'quai',
    'rampe',
    'residence',
    'rond',
    'route',
    'rue',
    'ruelle',
    'sentier',
    'square',
    'terrasse',
    'traverse',
    'villa',
    'voie',
    'zone',
  };

  /// Articles, particules et indices de répétition, en minuscules dès lors
  /// qu'ils ne commencent pas l'adresse.
  static const Set<String> _particles = {
    'a',
    'au',
    'aux',
    'bis',
    'd',
    'de',
    'des',
    'du',
    'en',
    'et',
    'l',
    'la',
    'le',
    'les',
    'quater',
    'sous',
    'sur',
    'ter',
  };

  /// Séparateurs internes à un mot : « SAINT-NAZAIRE » et « L'HERMITAGE » se
  /// capitalisent morceau par morceau.
  static const List<String> _innerSeparators = ['-', "'", '’'];

  static const Map<String, String> _accents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ÿ': 'y',
  };

  static String format(String address) {
    final words = address.trim().split(RegExp(r'\s+'));

    return [
      for (final (index, word) in words.indexed)
        _formatWord(word, isFirst: index == 0),
    ].join(' ');
  }

  static String _formatWord(String word, {required bool isFirst}) {
    // Un mot contenant un chiffre est un numéro ou un code : on n'y touche pas.
    if (word.contains(RegExp(r'[0-9]'))) {
      return word;
    }

    for (final separator in _innerSeparators) {
      if (word.contains(separator)) {
        final parts = word.split(separator);

        return [
          for (final (index, part) in parts.indexed)
            _formatWord(part, isFirst: isFirst && index == 0),
        ].join(separator);
      }
    }

    return _isLowercased(word, isFirst: isFirst)
        ? word.toLowerCase()
        : _capitalize(word);
  }

  static bool _isLowercased(String word, {required bool isFirst}) {
    final key = _normalize(word);

    if (key.isEmpty) {
      return false;
    }

    if (_streetTypes.contains(key)) {
      return true;
    }

    // Une particule qui ouvre l'adresse appartient au nom (« La Chapelle »).
    return !isFirst && _particles.contains(key);
  }

  /// Réduit un mot à ses lettres non accentuées, pour le comparer aux listes
  /// sans y dupliquer chaque variante.
  static String _normalize(String word) {
    final lowercased = word.toLowerCase();
    final buffer = StringBuffer();

    for (final rune in lowercased.runes) {
      final character = String.fromCharCode(rune);

      if (RegExp(r'[a-z]').hasMatch(character)) {
        buffer.write(character);
      } else if (_accents.containsKey(character)) {
        buffer.write(_accents[character]);
      }
    }

    return buffer.toString();
  }

  static String _capitalize(String word) {
    final letterIndex = word.indexOf(RegExp(r'\p{L}', unicode: true));

    if (letterIndex < 0) {
      return word;
    }

    final prefix = word.substring(0, letterIndex);
    final initial = word.substring(letterIndex, letterIndex + 1);
    final rest = word.substring(letterIndex + 1);

    return '$prefix${initial.toUpperCase()}${rest.toLowerCase()}';
  }
}
