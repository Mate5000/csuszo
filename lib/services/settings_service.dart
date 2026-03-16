import 'package:shared_preferences/shared_preferences.dart';

/// Az alkalmazás beállításait kezeli, SharedPreferences segítségével persistensen.
class SettingsService {
  static const _keySamplingIntervalMs = 'sampling_interval_ms';
  static const _keyTimeoutMs = 'timeout_ms';
  static const _keyStopConfirmCount = 'stop_confirm_count';
  static const _keyDevMaxSamples = 'dev_max_samples';
  static const _keyAutoSave = 'auto_save';

  // Alapértelmezett értékek
  static const int defaultSamplingIntervalMs = 50;
  static const int defaultTimeoutMs = 8000;
  static const int defaultStopConfirmCount = 6;
  static const int defaultDevMaxSamples = 200;
  static const bool defaultAutoSave = false;

  // Engedélyezett értékek
  static const List<int> samplingIntervalOptions = [20, 50, 100];
  static const List<int> timeoutOptions = [5000, 8000, 10000, 15000];
  static const List<int> stopConfirmOptions = [3, 6, 10];
  static const List<int> devMaxSamplesOptions = [100, 200, 500];

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Mintavételezési idő (ms) ---
  int get samplingIntervalMs =>
      _prefs.getInt(_keySamplingIntervalMs) ?? defaultSamplingIntervalMs;

  Future<void> setSamplingIntervalMs(int value) async {
    await _prefs.setInt(_keySamplingIntervalMs, value);
  }

  // --- Max mérési idő (ms) ---
  int get timeoutMs => _prefs.getInt(_keyTimeoutMs) ?? defaultTimeoutMs;

  Future<void> setTimeoutMs(int value) async {
    await _prefs.setInt(_keyTimeoutMs, value);
  }

  // --- Megállás megerősítési lépések ---
  int get stopConfirmCount =>
      _prefs.getInt(_keyStopConfirmCount) ?? defaultStopConfirmCount;

  Future<void> setStopConfirmCount(int value) async {
    await _prefs.setInt(_keyStopConfirmCount, value);
  }

  // --- Dev grafikon minták ---
  int get devMaxSamples =>
      _prefs.getInt(_keyDevMaxSamples) ?? defaultDevMaxSamples;

  Future<void> setDevMaxSamples(int value) async {
    await _prefs.setInt(_keyDevMaxSamples, value);
  }

  // --- Automatikus mentés ---
  bool get autoSave => _prefs.getBool(_keyAutoSave) ?? defaultAutoSave;

  Future<void> setAutoSave(bool value) async {
    await _prefs.setBool(_keyAutoSave, value);
  }

  /// Visszaállítja az összes beállítást az alapértelmezett értékre.
  Future<void> resetToDefaults() async {
    await _prefs.remove(_keySamplingIntervalMs);
    await _prefs.remove(_keyTimeoutMs);
    await _prefs.remove(_keyStopConfirmCount);
    await _prefs.remove(_keyDevMaxSamples);
    await _prefs.remove(_keyAutoSave);
  }
}