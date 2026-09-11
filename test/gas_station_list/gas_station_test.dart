import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Un mercredi, à 14h00.
  final now = DateTime(2026, 9, 9, 14);

  group('GasStation.fromJson', () {
    test('mappe chaque carburant sur son prix', () {
      final station = GasStation.fromJson({
        'id': '44000001',
        'adresse': '1 rue de la Paix',
        'ville': 'Nantes',
        'distance_m': 1250.0,
        'gazole_prix': '1,669',
        'e10_prix': 1.712,
      }, now: now);

      expect(station.id, '44000001');
      expect(station.address, '1 rue de la Paix');
      expect(station.city, 'Nantes');
      expect(station.distanceInKm, 1.25);
      expect(station.priceFor(FuelType.diesel), 1.669);
      expect(station.priceFor(FuelType.e10), 1.712);
      expect(station.priceFor(FuelType.sp98), isNull);
    });

    test('retombe sur des valeurs par défaut quand le JSON est vide', () {
      final station = GasStation.fromJson({}, now: now);

      expect(station.address, 'Adresse inconnue');
      expect(station.city, 'Ville inconnue');
      expect(station.distanceInKm, 0);
      expect(station.isOpen24h, isFalse);
      expect(station.closingTime, isNull);
      expect(station.isClosed, isFalse);
    });

    test('construit un identifiant de repli sans champ id', () {
      final station = GasStation.fromJson({
        'adresse': '1 rue de la Paix',
        'ville': 'Nantes',
      }, now: now);

      expect(station.id, '1 rue de la Paix-Nantes');
    });

    test('détecte un automate 24h/24', () {
      final station = GasStation.fromJson({
        'horaires_automate_24_24': 'Oui',
        'horaires_jour': 'Mercredi 07.30-20.00',
      }, now: now);

      expect(station.isOpen24h, isTrue);
      expect(station.closingTime, isNull);
      expect(station.isClosed, isFalse);
    });

    test('formate l\'heure de fermeture du jour courant', () {
      final station = GasStation.fromJson({
        'horaires_jour': 'Mardi 07.00-19.00, Mercredi 07.30-20.30',
      }, now: now);

      expect(station.closingTime, '20h30');
      expect(station.isClosed, isFalse);
    });

    test('marque la station fermée quand l\'heure est passée', () {
      final station = GasStation.fromJson({
        'horaires_jour': 'Mercredi 07.30-12.00',
      }, now: now);

      expect(station.isClosed, isTrue);
      expect(station.closingTime, isNull);
    });

    test('ignore un horaire illisible ou absent du jour', () {
      expect(
        GasStation.fromJson({'horaires_jour': 'n/a'}, now: now).closingTime,
        isNull,
      );
      expect(
        GasStation.fromJson({
          'horaires_jour': 'Lundi 07.30-20.00',
        }, now: now).closingTime,
        isNull,
      );
    });
  });
}
