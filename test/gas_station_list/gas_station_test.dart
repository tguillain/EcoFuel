import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Un mercredi, à 14h00.
  final now = DateTime(2026, 9, 9, 14);

  /// Toute station renvoyée par l'API porte une géométrie, le filtre
  /// within_distance l'exigeant : les charges utiles de test en portent donc
  /// une, sauf là où son absence est précisément ce qu'on vérifie.
  Map<String, dynamic> located(Map<String, dynamic> json) => {
    'geom': {'lat': 47.2184, 'lon': -1.5536},
    ...json,
  };

  group('GasStation.fromJson', () {
    test('mappe chaque carburant sur son prix', () {
      final station = GasStation.fromJson(located({
        'id': '44000001',
        'adresse': '1 rue de la Paix',
        'ville': 'Nantes',
        'distance_m': 1250.0,
        'gazole_prix': '1,669',
        'e10_prix': 1.712,
      }), now: now)!;

      expect(station.id, '44000001');
      expect(station.address, '1 rue de la Paix');
      expect(station.city, 'Nantes');
      expect(station.distanceInKm, 1.25);
      expect(station.priceFor(FuelType.diesel), 1.669);
      expect(station.priceFor(FuelType.e10), 1.712);
      expect(station.priceFor(FuelType.sp98), isNull);
      expect(station.latitude, 47.2184);
      expect(station.longitude, -1.5536);
    });

    // Plutôt que d'inventer une position, qui placerait la station au large du
    // golfe de Guinée et fausserait carte comme regroupement.
    test('écarte une station sans géométrie exploitable', () {
      expect(GasStation.fromJson({}, now: now), isNull);
      expect(GasStation.fromJson({'geom': 'n/a'}, now: now), isNull);
      expect(
        GasStation.fromJson({
          'geom': {'lat': 47.2184},
        }, now: now),
        isNull,
      );
    });

    test('accepte la forme GeoJSON de la géométrie', () {
      final station = GasStation.fromJson({
        'geom': {
          'coordinates': [-1.5536, 47.2184],
        },
      }, now: now);

      expect(station?.latitude, 47.2184);
      expect(station?.longitude, -1.5536);
    });

    test('retombe sur des valeurs par défaut quand le JSON est vide', () {
      final station = GasStation.fromJson(located({}), now: now)!;

      expect(station.address, 'Adresse inconnue');
      expect(station.city, 'Ville inconnue');
      expect(station.distanceInKm, 0);
      expect(station.isOpen24h, isFalse);
      expect(station.closingTime, isNull);
      expect(station.isClosed, isFalse);
    });

    test('construit un identifiant de repli sans champ id', () {
      final station = GasStation.fromJson(located({
        'adresse': '1 rue de la Paix',
        'ville': 'Nantes',
      }), now: now)!;

      expect(station.id, '1 rue de la Paix-Nantes');
    });

    test('détecte un automate 24h/24', () {
      final station = GasStation.fromJson(located({
        'horaires_automate_24_24': 'Oui',
        'horaires_jour': 'Mercredi 07.30-20.00',
      }), now: now)!;

      expect(station.isOpen24h, isTrue);
      expect(station.closingTime, isNull);
      expect(station.isClosed, isFalse);
    });

    test('formate l\'heure de fermeture du jour courant', () {
      final station = GasStation.fromJson(located({
        'horaires_jour': 'Mardi 07.00-19.00, Mercredi 07.30-20.30',
      }), now: now)!;

      expect(station.closingTime, '20h30');
      expect(station.isClosed, isFalse);
    });

    test('marque la station fermée quand l\'heure est passée', () {
      final station = GasStation.fromJson(located({
        'horaires_jour': 'Mercredi 07.30-12.00',
      }), now: now)!;

      expect(station.isClosed, isTrue);
      expect(station.closingTime, isNull);
    });

    test('ignore un horaire illisible ou absent du jour', () {
      expect(
        GasStation.fromJson(located({'horaires_jour': 'n/a'}), now: now)!.closingTime,
        isNull,
      );
      expect(
        GasStation.fromJson(located({
          'horaires_jour': 'Lundi 07.30-20.00',
        }), now: now)!.closingTime,
        isNull,
      );
    });
  });
}
