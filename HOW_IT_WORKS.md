# Csúszási Súrlódás Mérő — Működési Dokumentáció

Az app egy okostelefon gyorsulásmérőjével méri a csúszási súrlódási együtthatót (μ) vízszintes felületen.  
A logika a `mukodo/App.js` React-os referencia-appon alapul.

---

## Képlet

```
μ = átlagos_lassulás / g
```

ahol `g = 9.80665 m/s²`. Nincs dőlésszög, nincs gyroszkóp — egyszerű vízszintes csúsztatás.

---

## Fájlstruktúra

```
lib/
├── main.dart                        # Belépési pont, navigáció
├── models/
│   ├── measurement_result.dart      # Mérési eredmény adatmodellje
│   ├── material_pair.dart           # Referencia anyagpárok
│   └── sensor_sample.dart           # (legacy, már nem használt)
├── services/
│   ├── sensor_collector.dart        # Szenzor adatgyűjtés + mozgás/megállás detektálás
│   └── friction_calculator.dart     # μ kiszámítása a nyers adatokból
├── pages/
│   ├── measurement_page.dart        # Fő mérési képernyő (UI + állapotgép)
│   └── dev_page.dart                # Fejlesztői szenzor-vizualizáció
└── widgets/
    ├── accel_chart.dart             # Y-tengely gyorsulás diagram
    ├── result_card.dart             # Eredmény megjelenítése
    ├── friction_bar.dart            # μ vizuális skála
    └── mu_helpers.dart              # μ → szín, szöveges értékelés
```

---

## 1. `lib/services/sensor_collector.dart` — Adatgyűjtés

A `SensorCollector` osztály kezeli a teljes mérési ciklust.

### Konstansok

```dart
static const int _dataIntervalMs = 50;      // 20 Hz adatmentés
static const int _detectionIntervalMs = 100; // megállás-ellenőrzés gyakorisága
static const int _timeoutMs = 8000;          // biztonsági időkorlát (8 mp)
static const int _stopConfirmCount = 6;      // ennyi egymás utáni "megállt" check kell
static const double _moveThreshold = 0.2;   // g — ennél nagyobb → megmozdult
static const double _stopAvgThreshold = 0.1; // g — átlag alatt: megállt?
static const double _stopMaxThreshold = 0.15;// g — max alatt: megállt?
```

### Adatgyűjtés (20 Hz)

A szenzort ~60 Hz-en olvassuk, de csak 50 ms-enként mentjük el:

```dart
_accelSub = accelerometerEventStream(
  samplingPeriod: const Duration(milliseconds: 16),
).listen((event) {
  final now = DateTime.now();
  if (_lastDataTime == null ||
      now.difference(_lastDataTime!).inMilliseconds >= _dataIntervalMs) {
    // m/s² → g egység
    _collectedY.add(event.y / 9.80665);
    _lastDataTime = now;
    onProgress?.call(_collectedY.length);
  }
});
```

> **Miért Y tengely?** A telefon portrait módban tartva a Y tengely mutat előre/hátra — ez a csúsztatás iránya.

### Mozgás és megállás detektálás (100 ms-enként)

```dart
void _checkStopCondition() {
  if (!_isCollecting || _collectedY.length < 20) return;

  // Az utolsó 10 minta vizsgálata
  final lastValues = _collectedY.sublist(_collectedY.length - 10);
  final avgAbs = lastValues.map((v) => v.abs()).reduce((a, b) => a + b) / lastValues.length;
  final maxAbs = lastValues.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);

  // 1. fázis: mozgás detektálás
  if (!_hasMoved && maxAbs > _moveThreshold) {
    _hasMoved = true;
  }

  // 2. fázis: megállás detektálás (csak mozgás után)
  if (_hasMoved) {
    if (avgAbs < _stopAvgThreshold && maxAbs < _stopMaxThreshold) {
      _stoppedCounter++;
      if (_stoppedCounter >= _stopConfirmCount) {
        _finish(); // 6 × 100ms = 600ms biztos megállás után kész
      }
    } else {
      _stoppedCounter = 0; // reset ha megint mozog
    }
  }
}
```

### Mérési ciklus állapotai

```
startCollection() hívás
    │
    ▼
[Várakozás mozgásra]  ← maxAbs > 0.2g → _hasMoved = true
    │
    ▼
[Mozgás rögzítve]     ← adatok gyűlnek
    │
    ▼
[Megállás detektálás] ← avgAbs < 0.1g && maxAbs < 0.15g, 6×egymás után
    │                   VAGY 8 mp timeout
    ▼
onComplete(List<double> yData) callback
```

---

## 2. `lib/services/friction_calculator.dart` — μ Számítás

### Küszöbök (m/s²-ben)

```dart
static const double _accelerationThreshold  = 2.0;  // lökés fázis
static const double _steadyThreshold        = 1.5;  // egyenletes csúszás
static const double _decelerationThreshold  = 1.5;  // lassulás fázis
```

### Algoritmus

```dart
static MeasurementResult? calculate(List<double> yData) {
  // 1. g → m/s² konverzió
  final ms2 = yData.map((y) => y * g).toList();

  // 2. Fázis osztályozás
  final List<double> accelPhase = [];   // value > +2.0 m/s²  (lökés)
  final List<double> steadyPhase = [];  // |value| < 1.5 m/s² (egyenletes)
  final List<double> decelPhase = [];   // value < -1.5 m/s²  (lassulás/fékezés)

  for (final value in ms2) {
    if (value > _accelerationThreshold) {
      accelPhase.add(value);
    } else if (value < -_decelerationThreshold) {
      decelPhase.add(value);
    } else if (value.abs() < _steadyThreshold) {
      steadyPhase.add(value);
    }
  }

  // 3. Minimum 3 lassulási minta kell
  if (decelPhase.length < 3) return null;

  // 4. μ = átlagos lassulás / g
  final avgDecel = decelPhase.map((v) => v.abs()).reduce((a, b) => a + b) / decelPhase.length;
  final mu = (avgDecel / g).clamp(0.0, 2.0);

  return MeasurementResult(mu: mu, avgDeceleration: avgDecel, ...);
}
```

### Vizuális magyarázat

```
Y gyorsulás (m/s²)
     │
 +8  │   ██                        ← gyorsulás fázis (lökés)
 +4  │   ████
  0  ├──────────████████────────── ← egyenletes fázis
 -4  │               ████████████ ← lassulás fázis (súrlódás hatása)
 -8  │
     └──────────────────────────── idő (s)

μ = átlag(|lassulás fázis értékei|) / 9.80665
```

---

## 3. `lib/models/measurement_result.dart` — Adatmodell

```dart
class MeasurementResult {
  final double mu;                   // súrlódási együttható (0–2)
  final double avgDeceleration;      // átl. lassulás m/s²-ben
  final int accelSampleCount;        // összes minta száma
  final int accelerationPhaseCount;  // lökési fázis mintáinak száma
  final int steadyPhaseCount;        // egyenletes fázis mintáinak száma
  final int decelerationPhaseCount;  // lassulási fázis mintáinak száma
  final List<double> rawYData;       // nyers Y-adatok (g egységben, diagramhoz)
  final DateTime timestamp;          // mérés időpontja
}
```

---

## 4. `lib/pages/measurement_page.dart` — UI Állapotgép

```dart
enum _MeasureState { idle, measuring, calculating, done, error }
```

| Állapot | Megjelenítés | Mi történik |
|---------|-------------|-------------|
| `idle` | "MÉRÉS INDÍTÁSA" gomb | Vár a felhasználóra |
| `measuring` | Pulzáló kör, mintaszámláló | `SensorCollector` gyűjt |
| `calculating` | `CircularProgressIndicator` | `FrictionCalculator.calculate()` fut |
| `done` | `ResultCard` + `AccelChart` | Eredmény megjelenítve |
| `error` | Piros hibaüzenet | Kevés lassulási minta |

### Callbacks bekötése

```dart
_collector.onStarted = () {
  setState(() => _state = _MeasureState.measuring);
};

_collector.onProgress = (count) {
  setState(() => _dataCount = count); // élő mintaszámláló
};

_collector.onComplete = (yData) {
  setState(() => _state = _MeasureState.calculating);
  final result = FrictionCalculator.calculate(yData);
  if (result != null) {
    setState(() { _result = result; _state = _MeasureState.done; });
  } else {
    setState(() { _state = _MeasureState.error; });
  }
};
```

---

## 5. `lib/widgets/accel_chart.dart` — Diagram

A nyers Y-adatokat jeleníti meg m/s²-ben az idő függvényében (20 Hz → 0.05 s/minta):

```dart
for (int i = 0; i < result.rawYData.length; i++) {
  spots.add(FlSpot(i * 0.05, result.rawYData[i] * 9.80665));
  //               ^ idő (s)   ^ g → m/s² konverzió
}
```

---

## 6. `lib/widgets/result_card.dart` — Eredménykártya

Megjeleníti:
- `μ` értéke nagy betűkkel, színkódolással (`mu_helpers.dart`)
- Szöveges értékelés (pl. "Jó tapadás")
- `FrictionBar` — vizuális skála 0–1.5 között
- Fázis-statisztikák táblázat
- Figyelmeztetés ha `decelerationPhaseCount < 5`

```dart
if (result.decelerationPhaseCount < 5)
  Text('Kevés lassulási adat! Lökd meg erősebben!')
```

---

## Használat

1. Telefon portrait módban, sima vízszintes felületen
2. **MÉRÉS INDÍTÁSA** gomb megnyomása
3. A telefont meg kell lökni (csúszon el, majd álljon meg magától)
4. Az app automatikusan felismeri a mozgást és a megállást
5. Eredmény megjelenik μ értékkel és diagrammal

## Tipikus μ értékek

| Anyagpár | μ |
|----------|---|
| Gumi – aszfalt | 0.60–0.80 |
| Fa – fa | 0.25–0.50 |
| Jég – jég | 0.03–0.10 |
| Fém – fém | 0.15–0.45 |