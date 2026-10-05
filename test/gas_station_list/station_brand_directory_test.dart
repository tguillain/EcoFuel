import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/service/station_brand_directory.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
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

    // Une grande surface place parfois ses pompes loin de l'adresse déclarée.
    test('accepte le décalage d\'une station de grande surface', () {
      final brand = BrandMatcher.nearestBrand(
        [
          BrandedLocation(
            brand: 'Carrefour',
            latitude: latitudeShiftedBy(215),
            longitude: longitude,
          ),
        ],
        latitude: latitude,
        longitude: longitude,
      );

      expect(brand, 'Carrefour');
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

  group('CachingStationBrandDirectory', () {
    const center = UserCoordinates(latitude: latitude, longitude: longitude);

    const brands = [
      BrandedLocation(
        brand: 'TotalEnergies',
        latitude: latitude,
        longitude: longitude,
      ),
    ];

    Future<List<BrandedLocation>> lookUp(StationBrandDirectory directory) =>
        directory.brandsAround(center: center, radius: SearchRadius.fiveKm);

    test('ressert les dernières enseignes quand la source échoue', () async {
      final source = _FlakyBrandDirectory([brands, null]);
      final directory = CachingStationBrandDirectory(source);

      expect(await lookUp(directory), brands);
      expect(await lookUp(directory), brands);
    });

    test('remonte l\'échec tant qu\'aucune enseigne n\'est connue', () async {
      final directory = CachingStationBrandDirectory(
        _FlakyBrandDirectory([null]),
      );

      expect(lookUp(directory), throwsException);
    });
  });
}

/// Rejoue une suite de réponses ; `null` y figure un refus d'Overpass.
class _FlakyBrandDirectory implements StationBrandDirectory {
  _FlakyBrandDirectory(this._responses);

  final List<List<BrandedLocation>?> _responses;
  int _calls = 0;

  @override
  Future<List<BrandedLocation>> brandsAround({
    required UserCoordinates center,
    required SearchRadius radius,
  }) async {
    final response = _responses[_calls++];

    if (response == null) {
      throw Exception('Erreur Overpass : 504');
    }

    return response;
  }
}
