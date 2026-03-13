import 'package:flutter/material.dart';

/// Get a color representing the friction coefficient value.
Color muColor(double mu) {
  if (mu < 0.1) return const Color(0xFF00BCD4);
  if (mu < 0.3) return const Color(0xFF4CAF50);
  if (mu < 0.6) return const Color(0xFFFFC107);
  if (mu < 1.0) return const Color(0xFFFF9800);
  return const Color(0xFFF44336);
}

/// Get a human-readable evaluation of the friction coefficient.
String muEvaluation(double mu) {
  if (mu < 0.1) return 'Nagyon alacsony';
  if (mu < 0.3) return 'Alacsony';
  if (mu < 0.6) return 'Közepes';
  if (mu < 1.0) return 'Magas';
  return 'Nagyon magas';
}