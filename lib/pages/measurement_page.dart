import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/measurement_result.dart';
import '../models/material_pair.dart';
import '../services/sensor_collector.dart';
import '../services/friction_calculator.dart';
import '../widgets/result_card.dart';
import '../widgets/accel_chart.dart';
import '../widgets/mu_helpers.dart';

class MeasurementPage extends StatefulWidget {
  const MeasurementPage({super.key});

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

enum _MeasureState { idle, measuring, calculating, done, error }

class _MeasurementPageState extends State<MeasurementPage>
    with SingleTickerProviderStateMixin {
  _MeasureState _state = _MeasureState.idle;

  final SensorCollector _collector = SensorCollector();
  MeasurementResult? _result;
  String? _errorMessage;

  int _dataCount = 0;
  final List<MeasurementResult> _history = [];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _collector.onStarted = () {
      if (mounted) setState(() => _state = _MeasureState.measuring);
    };

    _collector.onProgress = (count) {
      if (mounted) setState(() => _dataCount = count);
    };

    _collector.onComplete = (yData) {
      if (mounted) setState(() => _state = _MeasureState.calculating);

      final result = FrictionCalculator.calculate(yData);

      if (mounted) {
        if (result != null) {
          setState(() {
            _result = result;
            _history.insert(0, result);
            _state = _MeasureState.done;
          });
          HapticFeedback.heavyImpact();
        } else {
          setState(() {
            _state = _MeasureState.error;
            _errorMessage =
                'Nem sikerült kiszámítani a súrlódási együtthatót.\n'
                'Gyűjtött minták: $_dataCount\n'
                'Lökd meg erősebben, hogy legyen lassulási fázis!';
          });
          HapticFeedback.heavyImpact();
        }
      }
    };
  }

  @override
  void dispose() {
    _collector.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startMeasurement() {
    setState(() {
      _state = _MeasureState.measuring;
      _result = null;
      _errorMessage = null;
      _dataCount = 0;
    });
    HapticFeedback.mediumImpact();
    _collector.startCollection();
  }

  void _reset() {
    _collector.cancel();
    setState(() {
      _state = _MeasureState.idle;
      _result = null;
      _errorMessage = null;
      _dataCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Csúszási súrlódási együttható mérő'),
            centerTitle: false,
            actions: [
              if (_state != _MeasureState.idle)
                IconButton(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Újrakezdés',
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Készítette: Kósa Máté, Hajzer Alexandra, Szántó Dávid, Pongrácz Ádám',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildStateContent(),

                if (_state == _MeasureState.done && _result != null) ...[
                  const SizedBox(height: 24),
                  ResultCard(result: _result!),
                  const SizedBox(height: 16),
                  AccelChart(result: _result!),
                ],

                if (_state == _MeasureState.error && _errorMessage != null) ...[
                  const SizedBox(height: 24),
                  _buildErrorCard(),
                ],

                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Előző mérések',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ..._history
                      .take(10)
                      .toList()
                      .asMap()
                      .entries
                      .map((e) => _buildHistoryTile(e.key, e.value)),
                ],

                const SizedBox(height: 24),
                Text(
                  'Referencia anyagpárok',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                ...referenceMaterialPairs.map((pair) => _buildMaterialPairTile(pair)),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.phone_android_rounded,
                color: colorScheme.onPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'μ = a (lassulás) / g',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nyomd meg a gombot és lökd meg a telefont egy sima felületen!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateContent() {
    switch (_state) {
      case _MeasureState.idle:
        return _buildIdleContent();
      case _MeasureState.measuring:
        return _buildMeasuringContent();
      case _MeasureState.calculating:
        return _buildCalculatingContent();
      case _MeasureState.done:
      case _MeasureState.error:
        return _buildDoneContent();
    }
  }

  Widget _buildIdleContent() {
    return Column(
      children: [
        _buildInstructions(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _startMeasurement,
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: const Text('MÉRÉS INDÍTÁSA'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasuringContent() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + 0.06 * _pulseController.value;
        return Column(
          children: [
            const SizedBox(height: 32),
            Transform.scale(
              scale: scale,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📊', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 4),
                    Text(
                      '$_dataCount adat',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mérés Folyamatban...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Várakozás a csúszásra és megállásra...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Mégse'),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildCalculatingContent() {
    return const Column(
      children: [
        SizedBox(height: 32),
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(strokeWidth: 4),
        ),
        SizedBox(height: 16),
        Text('Számítás...'),
      ],
    );
  }

  Widget _buildDoneContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              _reset();
              Future.delayed(
                const Duration(milliseconds: 100),
                _startMeasurement,
              );
            },
            icon: const Icon(Icons.replay_rounded, size: 28),
            label: const Text('ÚJ MÉRÉS'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage ?? 'Ismeretlen hiba',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    final steps = [
      ('1', 'Helyezd a telefont egy sima felületre'),
      ('2', 'Nyomd meg a "MÉRÉS INDÍTÁSA" gombot'),
      ('3', 'Lökd meg a telefont az Y tengely mentén'),
      ('4', 'Az app automatikusan feldolgozza az adatokat'),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Használat',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...steps.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            s.$1,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.$2,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(int index, MeasurementResult result) {
    final color = muColor(result.mu);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            'μ = ${result.mu.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'lassulás: ${result.avgDeceleration.toStringAsFixed(2)} m/s² · '
            '${result.accelSampleCount} minta',
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              muEvaluation(result.mu).split('(').first.trim(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialPairTile(MaterialPair pair) {
    final color = muColor(pair.mu);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: ListTile(
          leading: Text(pair.icon, style: const TextStyle(fontSize: 28)),
          title: Text(pair.name,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'μ = ${pair.mu.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  } 
}
