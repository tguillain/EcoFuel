import 'package:ecofuel/gas_station_list/formatter/address_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddressFormatter.format', () {
    // Adresses relevées telles quelles dans le flux de data.economie.gouv.fr,
    // dont la casse va des capitales intégrales au mélange.
    test('abaisse le type de voie et capitalise le nom', () {
      expect(
        AddressFormatter.format('205 ROUTE DE VANNES'),
        '205 route de Vannes',
      );
      expect(
        AddressFormatter.format('RUE GAETAN RONDEAU'),
        'rue Gaetan Rondeau',
      );
      expect(
        AddressFormatter.format('1 Impasse Ordronneau'),
        '1 impasse Ordronneau',
      );
      expect(
        AddressFormatter.format('80 Boulevard des Pas Enchantés'),
        '80 boulevard des Pas Enchantés',
      );
    });

    test('laisse intacte une adresse déjà bien formée', () {
      expect(
        AddressFormatter.format('173, route de Saint Joseph'),
        '173, route de Saint Joseph',
      );
    });

    test('garde les numéros et codes inchangés', () {
      expect(AddressFormatter.format('29 RUE DE LA BLORDIÈRE'), contains('29 '));
      expect(
        AddressFormatter.format('29 RUE DE LA BLORDIÈRE'),
        '29 rue de la Blordière',
      );
    });

    // Les composés se capitalisent morceau par morceau, particules exclues.
    test('traite les traits d\'union et les apostrophes', () {
      expect(
        AddressFormatter.format('12 AVENUE SAINT-SEBASTIEN-SUR-LOIRE'),
        '12 avenue Saint-Sebastien-sur-Loire',
      );
      expect(
        AddressFormatter.format('3 RUE DE L\'HERMITAGE'),
        '3 rue de l\'Hermitage',
      );
    });

    // Une particule qui ouvre l'adresse appartient au nom du lieu.
    test('capitalise une particule en tête d\'adresse', () {
      expect(AddressFormatter.format('LA CHAPELLE'), 'La Chapelle');
    });

    test('conserve les accents en les capitalisant', () {
      expect(
        AddressFormatter.format('110 BOULEVARD ÉGALITE'),
        '110 boulevard Égalite',
      );
    });

    test('ne bronche pas sur une chaîne vide', () {
      expect(AddressFormatter.format(''), '');
      expect(AddressFormatter.format('   '), '');
    });
  });
}
