import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Horizontal gradient bar showing where μ falls on the friction scale.
class FrictionBar extends StatelessWidget {
  final double mu;

  const FrictionBar({super.key, required this.mu});

  @override
  Widget build(BuildContext context) {
    final clampedMu = math.min(mu, 1.5);
    final fraction = clampedMu / 1.5;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
            Text('1.5+',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF00BCD4),
                        Color(0xFF4CAF50),
                        Color(0xFFFFC107),
                        Color(0xFFFF9800),
                        Color(0xFFF44336),
                      ],
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 4,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}