import 'package:ecofuel/gas_station_list/widget/gas_station_sheet_handle.dart';
import 'package:ecofuel/gas_station_list/widget/sheet_header_cross_fade.dart';
import 'package:ecofuel/gas_station_list/widget/sheet_scroll_view.dart';
import 'package:ecofuel/gas_station_list/widget/sheet_surface.dart';
import 'package:ecofuel/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Construit la carte, avec les bords que l'interface masque en ce moment et
/// ceux qu'elle masque au repos.
typedef CoveredMapBuilder = Widget Function(
  ValueListenable<EdgeInsets> coveredInsets,
  EdgeInsets framingInsets,
);

/// Construit le sliver du contenu de la feuille. [peekKey] désigne ce que la
/// feuille repliée doit laisser voir.
typedef SheetSliverBuilder = Widget Function(GlobalKey peekKey);

/// La carte en fond, les stations dans une feuille glissante par-dessus,
/// d'après les artboards « Carte · cartes flottantes » et « Liste seule » :
/// repliée sur la carte, la feuille devient la liste seule une fois tirée.
class MapListSheet extends StatefulWidget {
  const MapListSheet({
    super.key,
    required this.mapHeader,
    required this.listHeader,
    required this.mapBuilder,
    required this.sliverBuilder,
    required this.onRefresh,
    required this.floatsOnMap,
  });

  final Widget mapHeader;
  final Widget listHeader;
  final CoveredMapBuilder mapBuilder;
  final SheetSliverBuilder sliverBuilder;
  final Future<void> Function() onRefresh;

  /// Vrai quand la feuille montre des stations : repliée, elles flottent
  /// alors sans fond sur la carte. Un message ou un indicateur garde le sien,
  /// illisible sinon par-dessus les tuiles.
  final bool floatsOnMap;

  @override
  State<MapListSheet> createState() => _MapListSheetState();
}

class _MapListSheetState extends State<MapListSheet> {
  /// Bornes de la feuille repliée, en part de la hauteur sous l'en-tête. Sa
  /// taille réelle est celle de son contenu visible, mesurée après rendu : ces
  /// bornes ne jouent que sur un écran trop petit pour lui.
  static const double _minCollapsedSize = 0.1;
  static const double _maxCollapsedSize = 0.9;
  static const double _expandedSize = 1;

  /// Le fond de la feuille revient dès qu'on la tire, avant que les stations
  /// suivantes ne se mêlent aux repères de la carte.
  static const Interval _sheetFade = Interval(0, 0.25, curve: Curves.easeOut);

  static const Duration _sheetAnimation = Duration(milliseconds: 300);

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final GlobalKey _mapHeaderKey = GlobalKey();
  final GlobalKey _sheetAreaKey = GlobalKey();
  final GlobalKey _peekKey = GlobalKey();

  /// Taille de la feuille repliée, provisoire jusqu'à la première mesure.
  double _collapsedSize = 0.3;

  /// Hauteurs relevées après rendu, dont dépend la place laissée à la carte.
  double _mapHeaderHeight = 0;
  double _sheetAreaHeight = 0;

  /// Taille de la feuille, en part de la hauteur sous l'en-tête. L'en-tête et
  /// le fond de la feuille la suivent plutôt que le contrôleur, qui peut
  /// notifier en pleine construction de l'arbre.
  late final ValueNotifier<double> _sheetSize = ValueNotifier(_collapsedSize);

  /// Bords de la carte masqués en ce moment, que ses commandes suivent
  /// pendant le glisser de la feuille.
  final ValueNotifier<EdgeInsets> _coveredInsets = ValueNotifier(
    EdgeInsets.zero,
  );

  @override
  void initState() {
    super.initState();

    _sheetController.addListener(_onSheetMoved);
  }

  @override
  void dispose() {
    _sheetController.removeListener(_onSheetMoved);

    _sheetController.dispose();

    _sheetSize.dispose();

    _coveredInsets.dispose();

    super.dispose();
  }

  /// Avancement de la feuille, de 0 pour la vue carte à 1 pour la liste
  /// seule.
  double get _progress {
    final double progress =
        (_sheetSize.value - _collapsedSize) / (_expandedSize - _collapsedSize);

    return progress.clamp(0.0, 1.0);
  }

  bool get _isExpanded => _progress >= 0.5;

  double get _opacity =>
      widget.floatsOnMap ? _sheetFade.transform(_progress) : 1;

  /// Bords masqués quand la carte est au repos, feuille repliée.
  EdgeInsets get _framingInsets => EdgeInsets.only(
    top: _mapHeaderHeight,
    bottom: _collapsedSize * _sheetAreaHeight,
  );

  /// Tap sur la poignée : la feuille passe d'un bout à l'autre.
  void _toggle() {
    _sheetController.animateTo(
      _isExpanded ? _collapsedSize : _expandedSize,
      duration: _sheetAnimation,
      curve: Curves.easeOutCubic,
    );
  }

  /// La feuille signale aussi les changements de taille que provoque sa
  /// propre reconstruction, en pleine construction de l'arbre : y
  /// reconstruire l'en-tête ou la carte, ses voisins, est interdit. Ces
  /// signaux-là attendent la fin de l'image.
  void _onSheetMoved() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncSheetSize());

      return;
    }

    _syncSheetSize();
  }

  /// La hauteur vient de la fraction et non de `pixels` : juste après une
  /// reconstruction, la feuille ne connaît pas encore la place dont elle
  /// dispose et `pixels` vaut l'infini.
  void _syncSheetSize() {
    if (!mounted) {
      return;
    }

    final double size = _sheetController.isAttached
        ? _sheetController.size
        : _collapsedSize;

    _sheetSize.value = size;

    _coveredInsets.value = EdgeInsets.only(
      top: _mapHeaderHeight,
      bottom: size * _sheetAreaHeight,
    );
  }

  /// Relève après rendu les hauteurs dont dépendent la feuille repliée et la
  /// place laissée à la carte : elles suivent le texte des cartes, la taille
  /// de police choisie par l'utilisateur et celle de l'écran.
  void _measureLayout() {
    if (!mounted) {
      return;
    }

    final double? headerHeight = _mapHeaderKey.currentContext?.size?.height;
    final double? areaHeight = _sheetAreaKey.currentContext?.size?.height;
    final double? peekHeight = _peekKey.currentContext?.size?.height;

    if (headerHeight == null ||
        areaHeight == null ||
        peekHeight == null ||
        areaHeight == 0) {
      return;
    }

    final double collapsedSize =
        ((GasStationSheetHandle.height + peekHeight) / areaHeight).clamp(
          _minCollapsedSize,
          _maxCollapsedSize,
        );

    final bool changed =
        (collapsedSize - _collapsedSize).abs() > 0.001 ||
        (headerHeight - _mapHeaderHeight).abs() > 0.5 ||
        (areaHeight - _sheetAreaHeight).abs() > 0.5;

    if (changed) {
      final bool wasCollapsed = _progress < 0.001;

      setState(() {
        _collapsedSize = collapsedSize;
        _mapHeaderHeight = headerHeight;
        _sheetAreaHeight = areaHeight;
      });

      // Une feuille déjà manipulée garde sa position quand ses bornes
      // changent : repliée, elle doit suivre la nouvelle hauteur de son
      // contenu.
      if (wasCollapsed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _sheetController.isAttached) {
            _sheetController.jumpTo(collapsedSize);
          }
        });
      }
    }

    _syncSheetSize();
  }

  @override
  Widget build(BuildContext context) {
    // Lus pour reconstruire la feuille, et donc refaire les mesures, quand
    // l'écran change de taille ou l'utilisateur de taille de texte.
    MediaQuery.sizeOf(context);
    MediaQuery.textScalerOf(context);

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureLayout());

    return Stack(
      children: [
        Positioned.fill(
          child: widget.mapBuilder(_coveredInsets, _framingInsets),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: _sheetSize,
              builder: (context, _, _) => SheetHeaderCrossFade(
                progress: _progress,
                listHeader: widget.listHeader,
                mapHeader: KeyedSubtree(
                  key: _mapHeaderKey,
                  child: widget.mapHeader,
                ),
              ),
            ),
            Expanded(
              child: SizedBox.expand(key: _sheetAreaKey, child: _buildSheet()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSheet() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _collapsedSize,
      minChildSize: _collapsedSize,
      maxChildSize: _expandedSize,
      snap: true,
      builder: (context, scrollController) => ValueListenableBuilder<double>(
        valueListenable: _sheetSize,
        // Les coins s'équarrissent à mesure que le panneau de la liste
        // apparaît.
        builder: (context, _, child) => SheetSurface(
          opacity: _opacity,
          squareness: SheetHeaderCrossFade.listHeaderFade.transform(_progress),
          child: child!,
        ),
        child: SheetScrollView(
          controller: scrollController,
          onRefresh: widget.onRefresh,
          handle: ValueListenableBuilder<double>(
            valueListenable: _sheetSize,
            builder: (context, _, _) => SliverPersistentHeader(
              pinned: true,
              delegate: GasStationSheetHandle(
                isExpanded: _isExpanded,
                background: context.colors.background.withValues(
                  alpha: _opacity,
                ),
                onTap: _toggle,
              ),
            ),
          ),
          content: widget.sliverBuilder(_peekKey),
        ),
      ),
    );
  }
}
