import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('affiche plus de stations sur la carte quand le rayon grandit', () {
    expect(SearchRadius.fiveKm.mapStationLimit, 10);
    expect(SearchRadius.tenKm.mapStationLimit, 10);
    expect(SearchRadius.twentyFiveKm.mapStationLimit, 15);
    expect(SearchRadius.fiftyKm.mapStationLimit, 20);
  });
}
