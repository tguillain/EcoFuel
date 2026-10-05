import 'package:ecofuel/gas_station_detail/formatter/price_freshness_formatter.dart';
import 'package:ecofuel/gas_station_detail/formatter/station_service_formatter.dart';
import 'package:ecofuel/gas_station_detail/widget/freshness_note.dart';
import 'package:ecofuel/gas_station_detail/widget/headline_price.dart';
import 'package:ecofuel/gas_station_detail/widget/other_fuel_prices.dart';
import 'package:ecofuel/gas_station_detail/widget/route_bar.dart';
import 'package:ecofuel/gas_station_detail/widget/service_chips.dart';
import 'package:ecofuel/gas_station_list/enum/fuel_type.dart';
import 'package:ecofuel/gas_station_list/enum/search_radius.dart';
import 'package:ecofuel/gas_station_list/formatter/address_formatter.dart';
import 'package:ecofuel/gas_station_list/model/gas_station.dart';
import 'package:ecofuel/gas_station_list/model/route_result.dart';
import 'package:ecofuel/gas_station_list/service/route_service.dart';
import 'package:ecofuel/gas_station_list/service/user_locator.dart';
import 'package:ecofuel/gas_station_list/widget/gas_station_card.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Fiche d'une station, d'après l'artboard « Fiche station · éditoriale » :
/// le prix du carburant choisi en tête, les autres carburants et les services
/// dessous, l'itinéraire à portée de pouce.
class GasStationDetailPage extends StatefulWidget {
  const GasStationDetailPage({
    super.key,
    required this.station,
    required this.fuel,
    required this.radius,
    required this.userCoordinates,
    this.isCheapest = false,
    this.routeService = const RouteService(),
    this.now,
  });

  final GasStation station;
  final FuelType fuel;
  final SearchRadius radius;
  final UserCoordinates userCoordinates;

  /// La moins chère du rayon pour [fuel] : la fiche le dit en surtitre.
  final bool isCheapest;

  final RouteService routeService;

  /// N'existe que pour rendre l'ancienneté du relevé testable.
  final DateTime? now;

  /// Ouvre la fiche. Résout à `true` quand l'utilisateur demande l'itinéraire,
  /// que l'appelant affiche alors sur la carte.
  static Future<bool> open(
    BuildContext context, {
    required GasStation station,
    required FuelType fuel,
    required SearchRadius radius,
    required UserCoordinates userCoordinates,
    bool isCheapest = false,
    RouteService routeService = const RouteService(),
  }) async {
    final wantsRoute = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GasStationDetailPage(
          station: station,
          fuel: fuel,
          radius: radius,
          userCoordinates: userCoordinates,
          isCheapest: isCheapest,
          routeService: routeService,
        ),
      ),
    );

    return wantsRoute ?? false;
  }

  @override
  State<GasStationDetailPage> createState() => _GasStationDetailPageState();
}

class _GasStationDetailPageState extends State<GasStationDetailPage> {
  static const EdgeInsets _gutter = EdgeInsets.symmetric(horizontal: 26);

  static final NumberFormat _priceFormat = NumberFormat('0.000', 'fr_FR');
  static final NumberFormat _distanceFormat = NumberFormat('0.#', 'fr_FR');

  /// Durée du trajet en voiture, inconnue tant qu'OSRM n'a pas répondu.
  int? _routeMinutes;

  GasStation get _station => widget.station;

  @override
  void initState() {
    super.initState();

    _loadRouteDuration();
  }

  /// La durée n'est qu'un complément : en cas d'échec, la fiche s'en passe et
  /// la carte signalera l'erreur si l'itinéraire est demandé.
  Future<void> _loadRouteDuration() async {
    try {
      final RouteResult route = await widget.routeService.fetchRoute(
        start: widget.userCoordinates,
        destinationLatitude: _station.latitude,
        destinationLongitude: _station.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _routeMinutes = route.durationInMinutes.ceil();
      });
    } catch (_) {
      return;
    }
  }

  String get _eyebrow {
    final fuel = widget.fuel.label;

    if (widget.isCheapest) {
      return '$fuel · la moins chère à ${widget.radius.label}'.toUpperCase();
    }

    return '$fuel · à ${_distanceFormat.format(_station.distanceInKm)} km'
        .toUpperCase();
  }

  String get _fullAddress {
    final locality = [
      if (_station.postalCode != null) _station.postalCode,
      _station.city,
    ].join(' ');

    return '${AddressFormatter.format(_station.address)}, $locality';
  }

  String get _accessLine {
    return [
      '${_distanceFormat.format(_station.distanceInKm)} km',
      if (_routeMinutes != null) '$_routeMinutes min',
      if (_station.isOpen24h)
        'ouvert 24h/24'
      else if (_station.closingTime != null)
        'ouvert jusqu\'à ${_station.closingTime}'
      else if (_station.isClosed)
        'fermé',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final price = _station.priceFor(widget.fuel);
    final updatedAt = _station.priceUpdatedAtFor(widget.fuel);
    final services = StationServiceFormatter.labelsFor(_station);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Retour'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: _gutter.copyWith(top: 14, bottom: 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        Text(
                          _eyebrow,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 11,
                            letterSpacing: 11 * 0.14,
                            color: AppColors.onSurfaceFaint,
                          ),
                        ),
                        HeadlinePrice(
                          price: price != null
                              ? _priceFormat.format(price)
                              : '—',
                        ),
                        Text(
                          GasStationCard.titleFor(_station),
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 25 * -0.02,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          '$_fullAddress\n$_accessLine',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: AppColors.onSurfaceSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.outline)),
                ),
                padding: _gutter.copyWith(top: 20, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 20,
                  children: [
                    OtherFuelPrices(
                      station: _station,
                      selectedFuel: widget.fuel,
                      priceFormat: _priceFormat,
                    ),
                    if (services.isNotEmpty) ServiceChips(labels: services),
                    if (updatedAt != null)
                      FreshnessNote(
                        text: PriceFreshnessFormatter.format(
                          updatedAt,
                          now: widget.now ?? DateTime.now(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: RouteBar(
        minutes: _routeMinutes,
        onPressed: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
