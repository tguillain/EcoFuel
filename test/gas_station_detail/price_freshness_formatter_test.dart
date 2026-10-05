import 'package:ecofuel/gas_station_detail/formatter/price_freshness_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 5, 14);

  String format(Duration age) =>
      PriceFreshnessFormatter.format(now.subtract(age), now: now);

  group('PriceFreshnessFormatter', () {
    test('compte en minutes la première heure', () {
      expect(format(const Duration(minutes: 8)), 'Relevé il y a 8 min');
    });

    test('compte en heures le premier jour', () {
      expect(
        format(const Duration(hours: 3, minutes: 40)),
        'Relevé il y a 3 h',
      );
    });

    test('compte en jours au-delà', () {
      expect(format(const Duration(days: 1, hours: 2)), 'Relevé il y a 1 jour');
      expect(format(const Duration(days: 3)), 'Relevé il y a 3 jours');
    });

    // Une horloge de téléphone en avance sur le serveur.
    test('tient un relevé daté du futur pour tout frais', () {
      expect(format(const Duration(minutes: -5)), 'Relevé à l\'instant');
    });
  });
}
