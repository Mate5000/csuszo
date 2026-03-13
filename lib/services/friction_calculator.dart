import '../models/measurement_result.dart';

/// Friction coefficient calculator — same logic as the React app.
///
/// Steps:
///  1. Convert g → m/s²
///  2. Classify each sample into acceleration / steady / deceleration phases
///  3. μ = avgDeceleration / g
class FrictionCalculator {
  static const double g = 9.80665;

  // Thresholds in m/s² (same as React: 2.0 / 1.5 / 1.5)
  static const double _accelerationThreshold = 2.0;
  static const double _steadyThreshold = 1.5;
  static const double _decelerationThreshold = 1.5;

  /// [yData] — raw Y-axis values in g units, 20 Hz
  static MeasurementResult? calculate(List<double> yData) {
    if (yData.isEmpty) return null;

    final ms2 = yData.map((y) => y * g).toList();

    final List<double> accelPhase = [];
    final List<double> steadyPhase = [];
    final List<double> decelPhase = [];

    for (final value in ms2) {
      final abs = value.abs();
      if (value > _accelerationThreshold) {
        accelPhase.add(value);
      } else if (value < -_decelerationThreshold) {
        decelPhase.add(value);
      } else if (abs < _steadyThreshold) {
        steadyPhase.add(value);
      }
    }

    if (decelPhase.length < 3) return null;

    final avgDecel =
        decelPhase.map((v) => v.abs()).reduce((a, b) => a + b) / decelPhase.length;
    final mu = (avgDecel / g).clamp(0.0, 2.0);

    return MeasurementResult(
      mu: mu,
      avgDeceleration: avgDecel,
      accelSampleCount: yData.length,
      accelerationPhaseCount: accelPhase.length,
      steadyPhaseCount: steadyPhase.length,
      decelerationPhaseCount: decelPhase.length,
      rawYData: List.from(yData),
    );
  }
}
