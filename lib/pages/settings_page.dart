import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  final SettingsService settings;

  const SettingsPage({super.key, required this.settings});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int _samplingIntervalMs;
  late int _timeoutMs;
  late int _stopConfirmCount;
  late int _devMaxSamples;
  late bool _autoSave;

  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _samplingIntervalMs = widget.settings.samplingIntervalMs;
    _timeoutMs = widget.settings.timeoutMs;
    _stopConfirmCount = widget.settings.stopConfirmCount;
    _devMaxSamples = widget.settings.devMaxSamples;
    _autoSave = widget.settings.autoSave;
  }

  Future<void> _save() async {
    await widget.settings.setSamplingIntervalMs(_samplingIntervalMs);
    await widget.settings.setTimeoutMs(_timeoutMs);
    await widget.settings.setStopConfirmCount(_stopConfirmCount);
    await widget.settings.setDevMaxSamples(_devMaxSamples);
    await widget.settings.setAutoSave(_autoSave);
    _changed = true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beállítások mentve'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _reset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Visszaállítás'),
        content: const Text(
            'Biztosan visszaállítod az összes beállítást az alapértelmezettre?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Visszaállítás'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.settings.resetToDefaults();
      setState(() {
        _samplingIntervalMs = SettingsService.defaultSamplingIntervalMs;
        _timeoutMs = SettingsService.defaultTimeoutMs;
        _stopConfirmCount = SettingsService.defaultStopConfirmCount;
        _devMaxSamples = SettingsService.defaultDevMaxSamples;
        _autoSave = SettingsService.defaultAutoSave;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_changed) Navigator.of(context);
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('Beállítások'),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.restore_rounded),
                  tooltip: 'Alapértelmezések visszaállítása',
                  onPressed: _reset,
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Adatgyűjtés ─────────────────────────────────────────
                  _sectionHeader(context, 'Adatgyűjtés'),

                  _OptionTile<int>(
                    icon: Icons.sensors_rounded,
                    title: 'Mintavételezési idő',
                    subtitle:
                        'Milyen sűrűn mentse el a gyorsulásmérő adatait',
                    value: _samplingIntervalMs,
                    options: SettingsService.samplingIntervalOptions,
                    labelBuilder: (v) =>
                        '$v ms  (~${(1000 / v).round()} Hz)',
                    onChanged: (v) =>
                        setState(() => _samplingIntervalMs = v),
                  ),

                  _OptionTile<int>(
                    icon: Icons.timer_rounded,
                    title: 'Max. mérési idő',
                    subtitle:
                        'Ennyi idő után automatikusan leáll a mérés',
                    value: _timeoutMs,
                    options: SettingsService.timeoutOptions,
                    labelBuilder: (v) => '${v ~/ 1000} s',
                    onChanged: (v) => setState(() => _timeoutMs = v),
                  ),

                  _OptionTile<int>(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Megállás érzékenység',
                    subtitle:
                        'Hány egymást követő "csend" kell a megállás detektálásához',
                    value: _stopConfirmCount,
                    options: SettingsService.stopConfirmOptions,
                    labelBuilder: (v) => '$v lépés',
                    onChanged: (v) =>
                        setState(() => _stopConfirmCount = v),
                  ),

                  const Divider(height: 32),

                  // ── Dev nézet ────────────────────────────────────────────
                  _sectionHeader(context, 'Dev nézet'),

                  _OptionTile<int>(
                    icon: Icons.show_chart_rounded,
                    title: 'Grafikon minták száma',
                    subtitle:
                        'Hány mintát jelenítsen meg a Dev oldal grafikonja',
                    value: _devMaxSamples,
                    options: SettingsService.devMaxSamplesOptions,
                    labelBuilder: (v) => '$v db',
                    onChanged: (v) =>
                        setState(() => _devMaxSamples = v),
                  ),

                  const Divider(height: 32),

                  // ── Mentés ───────────────────────────────────────────────
                  _sectionHeader(context, 'Mentés'),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant,
                      ),
                    ),
                    child: SwitchListTile(
                      secondary: const Icon(Icons.save_alt_rounded),
                      title: const Text('Automatikus mentés'),
                      subtitle: const Text(
                          'Mérés után az eredményt automatikusan naplózza'),
                      value: _autoSave,
                      onChanged: (v) => setState(() => _autoSave = v),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Mentés'),
                      style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final T value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
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
                children: [
                  Icon(icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((opt) {
                  final selected = opt == value;
                  return ChoiceChip(
                    label: Text(labelBuilder(opt)),
                    selected: selected,
                    onSelected: (_) => onChanged(opt),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}