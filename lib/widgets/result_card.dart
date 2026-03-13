import 'package:flutter/material.dart';
import '../models/measurement_result.dart';
import 'friction_bar.dart';
import 'mu_helpers.dart';

class ResultCard extends StatelessWidget {
  final MeasurementResult result;

  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color = muColor(result.mu);
    final evaluation = muEvaluation(result.mu);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Eredmény',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            // μ érték
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'μ = ',
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                  ),
                  Text(
                    result.mu.toStringAsFixed(2),
                    style:
                        Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Értékelés
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                evaluation,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FrictionBar(mu: result.mu),
            const SizedBox(height: 16),
            // Mérési adatok kártya
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mérési adatok',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow('Összes adat', '${result.accelSampleCount}'),
                  _InfoRow('Gyorsulás fázis', '${result.accelerationPhaseCount} minta'),
                  _InfoRow('Egyenletes fázis', '${result.steadyPhaseCount} minta'),
                  _InfoRow('Lassulás fázis', '${result.decelerationPhaseCount} minta'),
                  _InfoRow('Átl. lassulás', '${result.avgDeceleration.toStringAsFixed(3)} m/s²'),
                  if (result.decelerationPhaseCount < 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Kevés lassulási adat! Lökd meg erősebben!',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
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
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
          ),
        ],
      ),
    );
  }
}
