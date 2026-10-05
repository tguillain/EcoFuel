import 'package:ecofuel/favorites/model/favorite_stations.dart';
import 'package:ecofuel/favorites/service/favorite_stations_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../gas_station_list/fake_gas_station_service.dart';

void main() {
  group('FavoriteStations', () {
    test('reprend les favoris enregistrés', () async {
      final favorites = FavoriteStations(
        InMemoryFavoriteStationsStore({'44000001'}),
      );

      await favorites.load();

      expect(favorites.contains('44000001'), isTrue);
    });

    test('ajoute puis retire une station, et l\'enregistre', () async {
      final store = InMemoryFavoriteStationsStore();
      final favorites = FavoriteStations(store);
      var notifications = 0;

      favorites.addListener(() => notifications++);

      await favorites.toggle('a');
      expect(favorites.ids, {'a'});
      expect(store.ids, {'a'});

      await favorites.toggle('a');
      expect(favorites.ids, isEmpty);
      expect(store.ids, isEmpty);
      expect(notifications, 2);
    });

    test('démarre sans favori quand le stockage est illisible', () async {
      final favorites = FavoriteStations(_BrokenStore());

      await favorites.load();

      expect(favorites.ids, isEmpty);
    });
  });
}

class _BrokenStore implements FavoriteStationsStore {
  @override
  Future<Set<String>> load() async => throw Exception('stockage indisponible');

  @override
  Future<void> save(Set<String> stationIds) async {}
}
