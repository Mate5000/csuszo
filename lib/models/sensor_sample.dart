/// Raw accelerometer sample (includes gravity), in g units from sensor.
class AccelSample {
  final double timestampMs; // milliseconds since measurement start
  final double x, y, z; // in g units (raw from sensor)

  AccelSample({
    required this.timestampMs,
    required this.x,
    required this.y,
    required this.z,
  });
}

/// Gyroscope sample in rad/s.
class GyroSample {
  final double timestampMs; // milliseconds since measurement start
  final double x, y, z; // rad/s

  GyroSample({
    required this.timestampMs,
    required this.x,
    required this.y,
    required this.z,
  });
}

/// Collected sensor data from a measurement session.
class SensorData {
  final List<AccelSample> accelSamples;
  final List<GyroSample> gyroSamples;
  final bool isLandscape;

  SensorData({
    required this.accelSamples,
    required this.gyroSamples,
    required this.isLandscape,
  });
}