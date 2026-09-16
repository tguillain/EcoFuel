import 'package:ecofuel/gas_station_list/service/station_brand_directory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 47.2184 / -1.5536 : centre de Nantes, comme en développement.
  const latitude = 47.2184;
  const longitude = -1.5536;

  /// Décale un point vers le nord d'une distance donnée, en s'appuyant sur le
  /// fait qu'un degré de latitude vaut environ 111 320 m.
  double latitudeShiftedBy(double meters) => latitude + meters / 111320;

  group('BrandMatcher.nearestBrand', () {
    test('retient l\'enseigne la plus proche dans la tolérance', () {
      final brand = BrandMatcher.nearestBrand(
        [
          BrandedLocation(
            brand: 'Esso',
            latitude: latitudeShiftedBy(120),
            longitude: longitude,
          ),
          BrandedLocation(
            brand: 'Intermarché',
            latitude: latitudeShiftedBy(30),
            longitude: longitude,
          ),
        ],
        latitude: latitude,
        longitude: longitude,
      );

      expect(brand, 'Intermarché');
    });

    // Les deux sources géocodent indépendamment : au-delà de la tolérance il
    // s'agit d'une autre station, mieux vaut aucune marque qu'une fausse.
    test('ignore une enseigne au-delà de la tolérance', () {
      final brand = BrandMatcher.nearestBrand(
        [
          BrandedLocation(
            brand: 'Total',
            latitude: latitudeShiftedBy(BrandMatcher.toleranceInMeters + 50),
            longitude: longitude,
          ),
        ],
        latitude: latitude,
        longitude: longitude,
      );

      expect(brand, isNull);
    });

    test('renvoie null sans aucune enseigne relevée', () {
      expect(
        BrandMatcher.nearestBrand(
          const [],
          latitude: latitude,
          longitude: longitude,
        ),
        isNull,
      );
    });
  });
}
