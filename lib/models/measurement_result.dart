/// Result of a friction coefficient measurement.
class MeasurementResult {
  /// Friction coefficient (μ)
  final double mu;

  /// Average deceleration magnitude during deceleration phase (m/s²)
  final double avgDeceleration;

  /// Number of accelerometer samples collected
  final int accelSampleCount;

  /// Phase sample counts
  final int accelerationPhaseCount;
  final int steadyPhaseCount;
  final int decelerationPhaseCount;

  /// Raw Y-axis data (in g units) for charting
  final List<double> rawYData;

  /// Timestamp of measurement
  final DateTime timestamp;

  MeasurementResult({
    required this.mu,
    required this.avgDeceleration,
    required this.accelSampleCount,
    required this.accelerationPhaseCount,
    required this.steadyPhaseCount,
    required this.decelerationPhaseCount,
    required this.rawYData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
