import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/settings_service.dart';

/// Dev page for real-time sensor data visualization.
class DevPage extends StatefulWidget {
  final SettingsService settings;

  const DevPage({super.key, required this.settings});

  @override
  State<DevPage> createState() => _DevPageState();
}

class _DevPageState extends State<DevPage> {
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<AccelerometerEvent>? _rawAccelSub;

  int get _maxSamples => widget.settings.devMaxSamples;
  final List<_TimedVec3> _accelData = [];
  final List<_TimedVec3> _gyroData = [];
  final List<_TimedVec3> _rawAccelData = [];

  DateTime? _startTime;
  bool _isRecording = false;

  double _currentAx = 0, _currentAy = 0, _currentAz = 0;
  double _currentGx = 0, _currentGy = 0, _currentGz = 0;
  double _currentRawAx = 0, _currentRawAy = 0, _currentRawAz = 0;

  @override
  void dispose() {
    _stopRecording();
    super.dispose();
  }

  double _elapsed() {
    if (_startTime == null) return 0;
    return DateTime.now().difference(_startTime!).inMicroseconds / 1e6;
  }

  void _startRecording() {
    _startTime = DateTime.now();
    _accelData.clear();
    _gyroData.clear();
    _rawAccelData.clear();

    _accelSub = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((e) {
      _currentAx = e.x;
      _currentAy = e.y;
      _currentAz = e.z;
      final t = _elapsed();
      setState(() {
        _accelData.add(_TimedVec3(t, e.x, e.y, e.z));
        if (_accelData.length > _maxSamples) _accelData.removeAt(0);
      });
    });

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((e) {
      _currentGx = e.x;
      _currentGy = e.y;
      _currentGz = e.z;
      final t = _elapsed();
      setState(() {
        _gyroData.add(_TimedVec3(t, e.x, e.y, e.z));
        if (_gyroData.length > _maxSamples) _gyroData.removeAt(0);
      });
    });

    _rawAccelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((e) {
      _currentRawAx = e.x;
      _currentRawAy = e.y;
      _currentRawAz = e.z;
      final t = _elapsed();
      setState(() {
        _rawAccelData.add(_TimedVec3(t, e.x, e.y, e.z));
        if (_rawAccelData.length > _maxSamples) _rawAccelData.removeAt(0);
      });
    });

    setState(() => _isRecording = true);
  }

  void _stopRecording() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _rawAccelSub?.cancel();
    _accelSub = null;
    _gyroSub = null;
    _rawAccelSub = null;
    if (mounted) setState(() => _isRecording = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Dev – Szenzorok'),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Start/stop button
                SizedBox(
                  width: double.infinity,
                  child: _isRecording
                      ? OutlinedButton.icon(
                          onPressed: _stopRecording,
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('Rögzítés leállítása'),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: _startRecording,
                          icon: const Icon(
                              Icons.fiber_manual_record_rounded),
                          label: const Text('Rögzítés indítása'),
                          style: FilledButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // Current values
                _buildCurrentValues(),
                const SizedBox(height: 20),

                // User accelerometer chart
                _buildChartCard(
                  title: 'User Accelerometer (gravitáció nélkül)',
                  unit: 'm/s²',
                  data: _accelData,
                  colors: [Colors.red, Colors.green, Colors.blue],
                  labels: ['X', 'Y', 'Z'],
                ),
                const SizedBox(height: 16),

                // Raw accelerometer chart
                _buildChartCard(
                  title: 'Raw Accelerometer (gravitációval)',
                  unit: 'm/s²',
                  data: _rawAccelData,
                  colors: [
                    Colors.red.shade300,
                    Colors.green.shade300,
                    Colors.blue.shade300,
                  ],
                  labels: ['X', 'Y', 'Z'],
                ),
                const SizedBox(height: 16),

                // Gyroscope chart
                _buildChartCard(
                  title: 'Gyroscope',
                  unit: 'rad/s',
                  data: _gyroData,
                  colors: [Colors.orange, Colors.purple, Colors.teal],
                  labels: ['X', 'Y', 'Z'],
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentValues() {
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
              'Jelenlegi értékek',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _buildValueRow(
                'Accel (user)',
                _currentAx,
                _currentAy,
                _currentAz,
                'm/s²',
                Colors.red,
                Colors.green,
                Colors.blue),
            const SizedBox(height: 8),
            _buildValueRow(
                'Accel (raw)',
                _currentRawAx,
                _currentRawAy,
                _currentRawAz,
                'm/s²',
                Colors.red.shade300,
                Colors.green.shade300,
                Colors.blue.shade300),
            const SizedBox(height: 8),
            _buildValueRow(
                'Gyroscope',
                _currentGx,
                _currentGy,
                _currentGz,
                'rad/s',
                Colors.orange,
                Colors.purple,
                Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildValueRow(String label, double x, double y, double z,
      String unit, Color cx, Color cy, Color cz) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                )),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildValueChip('X', x, unit, cx),
            const SizedBox(width: 8),
            _buildValueChip('Y', y, unit, cy),
            const SizedBox(width: 8),
            _buildValueChip('Z', z, unit, cz),
          ],
        ),
      ],
    );
  }

  Widget _buildValueChip(String axis, double val, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$axis: ${val.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String unit,
    required List<_TimedVec3> data,
    required List<Color> colors,
    required List<String> labels,
  }) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  unit,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Legend
            Row(
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(labels[i],
                          style: TextStyle(
                            fontSize: 11,
                            color: colors[i],
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: data.isEmpty
                  ? Center(
                      child: Text(
                        _isRecording
                            ? 'Várakozás adatra...'
                            : 'Indítsd el a rögzítést',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 5,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: 0.5),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              interval: 1,
                              getTitlesWidget: (value, meta) => Text(
                                '${value.toStringAsFixed(0)}s',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          _line(
                              data
                                  .map((d) => FlSpot(d.t, d.x))
                                  .toList(),
                              colors[0]),
                          _line(
                              data
                                  .map((d) => FlSpot(d.t, d.y))
                                  .toList(),
                              colors[1]),
                          _line(
                              data
                                  .map((d) => FlSpot(d.t, d.z))
                                  .toList(),
                              colors[2]),
                        ],
                        lineTouchData:
                            const LineTouchData(enabled: false),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.15,
      color: color,
      barWidth: 1.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
    );
  }
}

class _TimedVec3 {
  final double t;
  final double x, y, z;
  _TimedVec3(this.t, this.x, this.y, this.z);
}