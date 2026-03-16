import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

/// Collects accelerometer Y-axis data.
/// Logic mirrors the React app:
///  - Configurable data collection interval (default 50 ms = 20 Hz)
///  - Detects movement (maxAbs > 0.2g on Y axis)
///  - Detects stop (avgAbs < 0.1g AND maxAbs < 0.15g for N consecutive checks)
///  - Configurable safety timeout (default 8 seconds)
class SensorCollector {
  static const int _detectionIntervalMs = 100; // megállás detektálás
  static const double _moveThreshold = 0.2; // g
  static const double _stopAvgThreshold = 0.1; // g
  static const double _stopMaxThreshold = 0.15; // g

  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _detectionTimer;
  Timer? _timeoutTimer;

  final List<double> _collectedY = []; // g egységben
  bool _hasMoved = false;
  int _stoppedCounter = 0;
  DateTime? _lastDataTime;

  bool _isCollecting = false;
  bool get isCollecting => _isCollecting;

  /// Called when collection finishes with raw Y data.
  void Function(List<double> yData)? onComplete;

  /// Called periodically with current sample count.
  void Function(int count)? onProgress;

  /// Called when collection starts (movement detected).
  void Function()? onStarted;

  /// Elindítja a szenzor adatgyűjtést.
  /// [dataIntervalMs] – milyen sűrűn mentse el a mintákat (ms).
  /// [timeoutMs] – max mérési idő (ms).
  /// [stopConfirmCount] – hány egymást követő "csend" kell a megálláshoz.
  void startCollection({
    int dataIntervalMs = 50,
    int timeoutMs = 8000,
    int stopConfirmCount = 6,
  }) {
    if (_isCollecting) return;

    _isCollecting = true;
    _collectedY.clear();
    _hasMoved = false;
    _stoppedCounter = 0;
    _lastDataTime = null;

    onStarted?.call();

    // ~60 Hz szenzor olvasás, de csak `dataIntervalMs`-ként mentjük
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 10),
    ).listen((event) {
      if (!_isCollecting) return;

      final now = DateTime.now();
      if (_lastDataTime == null ||
          now.difference(_lastDataTime!).inMilliseconds >= dataIntervalMs) {
        // sensors_plus m/s²-ben ad, osztjuk 9.80665-tel → g egység
        _collectedY.add(event.y / 9.80665);
        _lastDataTime = now;
        onProgress?.call(_collectedY.length);
      }
    });

    // Megállás detektálás 100 ms-ként
    _detectionTimer = Timer.periodic(
        const Duration(milliseconds: _detectionIntervalMs), (_) {
      _checkStopCondition(stopConfirmCount);
    });

    // Biztonsági timeout
    _timeoutTimer = Timer(Duration(milliseconds: timeoutMs), () {
      _finish();
    });
  }

  void _checkStopCondition(int stopConfirmCount) {
    if (!_isCollecting || _collectedY.length < 20) return;

    final lastValues = _collectedY.length >= 10
        ? _collectedY.sublist(_collectedY.length - 10)
        : _collectedY;

    final avgAbs = lastValues.map((v) => v.abs()).reduce((a, b) => a + b) /
        lastValues.length;
    final maxAbs =
        lastValues.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);

    // Mozgás detektálás
    if (!_hasMoved && maxAbs > _moveThreshold) {
      _hasMoved = true;
    }

    // Megállás detektálás (csak ha volt mozgás)
    if (_hasMoved) {
      if (avgAbs < _stopAvgThreshold && maxAbs < _stopMaxThreshold) {
        _stoppedCounter++;
        if (_stoppedCounter >= stopConfirmCount) {
          _finish();
        }
      } else {
        _stoppedCounter = 0;
      }
    }
  }

  void _finish() {
    if (!_isCollecting) return;
    _isCollecting = false;
    _accelSub?.cancel();
    _detectionTimer?.cancel();
    _timeoutTimer?.cancel();
    _accelSub = null;
    _detectionTimer = null;
    _timeoutTimer = null;

    onComplete?.call(List.from(_collectedY));
  }

  void cancel() {
    _isCollecting = false;
    _accelSub?.cancel();
    _detectionTimer?.cancel();
    _timeoutTimer?.cancel();
    _accelSub = null;
    _detectionTimer = null;
    _timeoutTimer = null;
    _collectedY.clear();
  }

  void dispose() {
    cancel();
  }
}