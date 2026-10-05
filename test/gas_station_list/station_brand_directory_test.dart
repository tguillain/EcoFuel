import 'dart:convert';

import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/service/station_brand_directory.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:flutter/services.dart';
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

  group('AssetStationBrandDirectory', () {
    const center = UserCoordinates(latitude: latitude, longitude: longitude);

    // Une station dans le rayon, une juste au-delà, une à Paris.
    final bundle = _FakeAssetBundle('''
{"source": "OSM", "generatedAt": "2026-10-05", "stations": [
  [$latitude, $longitude, "TotalEnergies"],
  [${latitudeShiftedBy(5500)}, $longitude, "Esso"],
  [48.8566, 2.3522, "Shell"]
]}
''');

    test('ne garde que les enseignes autour du centre', () async {
      final brands = await AssetStationBrandDirectory(bundle: bundle)
          .brandsAround(center: center, radius: SearchRadius.fiveKm);

      expect(brands.map((brand) => brand.brand), ['TotalEnergies']);
    });

    test('élargit la recherche avec le rayon', () async {
      final brands = await AssetStationBrandDirectory(bundle: bundle)
          .brandsAround(center: center, radius: SearchRadius.tenKm);

      expect(brands.map((brand) => brand.brand), ['TotalEnergies', 'Esso']);
    });

    // L'application livre le relevé : un fichier absent ou vide priverait
    // en silence toutes les stations de leur nom.
    test('livre un relevé couvrant la France', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final brands = await AssetStationBrandDirectory().brandsAround(
        center: center,
        radius: SearchRadius.fiveKm,
      );

      expect(brands.length, greaterThan(20));
    });
  });
}

/// Sert un contenu fixe à la place du fichier livré avec l'application.
class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._content);

  final String _content;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(utf8.encode(_content));

  @override
  Future<String> loadString(String key, {bool cache = true}) async => _content;
}
