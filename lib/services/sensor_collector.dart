import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

/// Collects accelerometer Y-axis data.
/// Logic mirrors the React app:
///  - 20 Hz data collection (50 ms intervals)
///  - Detects movement (maxAbs > 0.2g on Y axis)
///  - Detects stop (avgAbs < 0.1g AND maxAbs < 0.15g for 6 consecutive checks)
///  - Safety timeout: 8 seconds
class SensorCollector {
  static const int _dataIntervalMs = 50; // 20 Hz adatgyűjtés
  static const int _detectionIntervalMs = 100; // megállás detektálás
  static const int _timeoutMs = 8000; // max mérési idő
  static const int _stopConfirmCount = 6; // hány check kell a megálláshoz
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

  void startCollection() {
    if (_isCollecting) return;

    _isCollecting = true;
    _collectedY.clear();
    _hasMoved = false;
    _stoppedCounter = 0;
    _lastDataTime = null;

    onStarted?.call();

    // ~60 Hz szenzor olvasás, de csak 20 Hz-en mentjük
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 10),
    ).listen((event) {
      if (!_isCollecting) return;

      final now = DateTime.now();
      if (_lastDataTime == null ||
          now.difference(_lastDataTime!).inMilliseconds >= _dataIntervalMs) {
        // sensors_plus m/s²-ben ad, osztjuk 9.80665-tel → g egység
        _collectedY.add(event.y / 9.80665);
        _lastDataTime = now;
        onProgress?.call(_collectedY.length);
      }
    });

    // Megállás detektálás 100 ms-ként
    _detectionTimer =
        Timer.periodic(const Duration(milliseconds: _detectionIntervalMs), (_) {
      _checkStopCondition();
    });

    // Biztonsági timeout
    _timeoutTimer = Timer(const Duration(milliseconds: _timeoutMs), () {
      _finish();
    });
  }

  void _checkStopCondition() {
    if (!_isCollecting || _collectedY.length < 20) return;

    final lastValues = _collectedY.length >= 10
        ? _collectedY.sublist(_collectedY.length - 10)
        : _collectedY;

    final avgAbs =
        lastValues.map((v) => v.abs()).reduce((a, b) => a + b) / lastValues.length;
    final maxAbs = lastValues.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);

    // Mozgás detektálás
    if (!_hasMoved && maxAbs > _moveThreshold) {
      _hasMoved = true;
    }

    // Megállás detektálás (csak ha volt mozgás)
    if (_hasMoved) {
      if (avgAbs < _stopAvgThreshold && maxAbs < _stopMaxThreshold) {
        _stoppedCounter++;
        if (_stoppedCounter >= _stopConfirmCount) {
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
