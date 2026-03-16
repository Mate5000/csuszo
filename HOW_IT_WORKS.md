# Mű – Csúszási súrlódásegyüttható-mérő

> Flutter alkalmazás, amely az okostelefon gyorsulásmérőjét használva méri két felület közötti kinematikus súrlódási együtthatót (μ).

---

## Tartalom

1. [Fizikai elv](#fizikai-elv)
2. [Projektstruktúra](#projektstruktúra)
3. [Adatfolyam](#adatfolyam)
4. [Modulok részletezve](#modulok-részletezve)
   - [main.dart](#maindart)
   - [SettingsService](#settingsservice)
   - [SensorCollector](#sensorcollector)
   - [FrictionCalculator](#frictioncalculator)
   - [MeasurementPage](#measurementpage)
   - [SettingsPage](#settingspage)
   - [DevPage](#devpage)
   - [Widgetek](#widgetek)
5. [Beállítások](#beállítások)
6. [Referencia anyagpárok](#referencia-anyagpárok)

---

## Fizikai elv

$$\mu = \frac{a_{\text{lassulás}}}{g}$$

A telefont sima felületre fektetjük, majd meglökjük. Miután elválik a kezünktől, a felszíni súrlódás lassítja le. A gyorsulásmérő Y tengelye rögzíti ezt a lassulást; g = 9,80665 m/s².

**Fázisok:**

| Fázis | Feltétel (m/s²) | Szerepe |
|---|---|---|
| Gyorsulás | `Y > +2.0` | Lökés ujjal |
| Stabil | `\|Y\| < 1.5` | Egyenletes csúszás |
| **Lassulás** | `Y < −1.5` | **μ kiszámításához** |

$$\mu = \frac{\overline{|a_{\text{lassulás}}|}}{g} \in [0,\, 2]$$

---

## Projektstruktúra

```
lib/
├── main.dart                   # Belépési pont, CsuszoApp, HomePage
├── models/
│   ├── measurement_result.dart # Mérési eredmény adatmodell
│   ├── material_pair.dart      # Referencia anyagpár adatmodell + lista
│   └── sensor_sample.dart      # (örökölt, nem aktívan használt)
├── services/
│   ├── settings_service.dart   # SharedPreferences-alapú beállítások
│   ├── sensor_collector.dart   # Gyorsulásmérő adatgyűjtés + auto-stop
│   └── friction_calculator.dart# Fázisdetektálás + μ kiszámítása
├── pages/
│   ├── measurement_page.dart   # Főoldal (mérés indítása, eredmény)
│   ├── settings_page.dart      # Beállítások oldal
│   └── dev_page.dart           # Dev oldal (valós idejű szenzor grafikon)
└── widgets/
    ├── result_card.dart        # Eredmény kártya widget
    ├── accel_chart.dart        # Y-tengely gyorsulás grafikon
    ├── mu_helpers.dart         # μ → szín + szöveges értékelés
    ├── friction_bar.dart       # (örökölt widget)
    └── mu_helpers.dart
```

---

## Adatfolyam

```
Felhasználó lök
       │
       ▼
SensorCollector.startCollection()
  └─ accelerometerEventStream (10 ms-es polling)
  └─ 50 ms-ként Y értéket ment g-be konvertálva
  └─ 100 ms-ként megállás-detektálás
  └─ timeout után automatikus leállás
       │
       ▼ onComplete(List<double> yData)
FrictionCalculator.calculate(yData)
  └─ g → m/s² konverzió
  └─ fázis besorolás (gyorsulás / stabil / lassulás)
  └─ μ = átl. lassulás / g
       │
       ▼ MeasurementResult
MeasurementPage
  └─ ResultCard      (μ + statisztikák)
  └─ AccelChart      (Y tengely időgrafikon)
  └─ előzmények listája
```

---

## Modulok részletezve

### main.dart

Az alkalmazás belépési pontja. `SettingsService`-t inicializál, majd átadja az egész widget-fának.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final settings = SettingsService();
  await settings.init();           // SharedPreferences betöltése
  runApp(CsuszoApp(settings: settings));
}
```

`HomePage` két tabból áll (`NavigationBar`):

| Tab | Widget | Leírás |
|---|---|---|
| Mérés | `MeasurementPage` | Mérés indítása, eredmény |
| Dev | `DevPage` | Valós idejű szenzor nézet |

---

### SettingsService

`lib/services/settings_service.dart`

`SharedPreferences`-t használ; az értékek **újraindítás után is megmaradnak**.

```dart
final settings = SettingsService();
await settings.init();

// Olvasás
int ms = settings.samplingIntervalMs;   // default: 50
int to = settings.timeoutMs;            // default: 8000
int sc = settings.stopConfirmCount;     // default: 6
int dm = settings.devMaxSamples;        // default: 200
bool as = settings.autoSave;            // default: false

// Írás
await settings.setSamplingIntervalMs(20);
await settings.setTimeoutMs(10000);

// Visszaállítás
await settings.resetToDefaults();
```

**Elérhető opciók:**

| Beállítás | Kulcs | Opciók | Default |
|---|---|---|---|
| Mintavételezési idő | `sampling_interval_ms` | 20 / 50 / 100 ms | 50 ms |
| Max. mérési idő | `timeout_ms` | 5 / 8 / 10 / 15 s | 8 s |
| Megállás érzékenység | `stop_confirm_count` | 3 / 6 / 10 lépés | 6 |
| Dev grafikon minták | `dev_max_samples` | 100 / 200 / 500 | 200 |
| Automatikus mentés | `auto_save` | be / ki | ki |

---

### SensorCollector

`lib/services/sensor_collector.dart`

Gyűjti az Y-tengelyes gyorsulásmérő adatokat, és **automatikusan megáll**, ha a telefon megáll.

```dart
final collector = SensorCollector();

// Callback-ek beállítása
collector.onStarted  = ()              { /* mérés elindult */ };
collector.onProgress = (int count)     { /* UI frissítés */ };
collector.onComplete = (List<double> y){ /* feldolgozás */ };

// Indítás (a beállításokból jövő paraméterekkel)
collector.startCollection(
  dataIntervalMs:   50,   // mennyire sűrűn mentse a mintákat
  timeoutMs:        8000, // max mérési idő ms-ban
  stopConfirmCount: 6,    // hány egymást követő "csend" = megállt
);

// Megszakítás
collector.cancel();
```

**Belső logika:**

```
Szenzor poll: 10 ms-ként (hardware-hez kötve)
Adat mentés:  csak ha az utolsó mentés óta ≥ dataIntervalMs telt el
              Y értéke: event.y / 9.80665  (m/s² → g)

Megállás-detektálás (100 ms-ként):
  lastValues = utolsó 10 minta
  avgAbs = átlag(|y|)
  maxAbs = max(|y|)

  Ha még nem volt mozgás ÉS maxAbs > 0.2g  → _hasMoved = true
  Ha volt mozgás ÉS avgAbs < 0.1g ÉS maxAbs < 0.15g:
    _stoppedCounter++
    Ha _stoppedCounter ≥ stopConfirmCount → _finish()
  Egyébként:
    _stoppedCounter = 0
```

---

### FrictionCalculator

`lib/services/friction_calculator.dart`

Statikus osztály, `List<double>` (g egységű Y adatok) → `MeasurementResult?`.

```dart
MeasurementResult? result = FrictionCalculator.calculate(yData);
// null, ha < 3 lassulási minta volt (nem érvényes mérés)
```

**Algoritmus:**

```dart
const g = 9.80665;
// Küszöbök m/s²-ban:
const _accelerationThreshold  =  2.0;  // Y > +2.0  → gyorsulás
const _decelerationThreshold  =  1.5;  // Y < -1.5  → lassulás
const _steadyThreshold        =  1.5;  // |Y| < 1.5 → stabil

// Fázisok szétválasztása:
for (final value in yData.map((y) => y * g)) {
  if (value > _accelerationThreshold)   accelPhase.add(value);
  else if (value < -_decelerationThreshold) decelPhase.add(value);
  else if (value.abs() < _steadyThreshold)  steadyPhase.add(value);
}

// μ kiszámítása:
if (decelPhase.length < 3) return null;        // nem érvényes
avgDecel = mean(decelPhase.map(|v|))           // átl. lassulás (m/s²)
mu       = (avgDecel / g).clamp(0.0, 2.0)     // μ ∈ [0, 2]
```

---

### MeasurementPage

`lib/pages/measurement_page.dart`

A főoldal; `SliverAppBar.large`-t használ. Állapotgép:

```
idle → measuring → calculating → done
                              ↘ error
```

| Állapot | Megjelenítés |
|---|---|
| `idle` | Útmutató + „MÉRÉS INDÍTÁSA" gomb |
| `measuring` | Pulzáló kör + mintaszám, „Mégse" gomb |
| `calculating` | `CircularProgressIndicator` |
| `done` | `ResultCard` + `AccelChart` + „ÚJ MÉRÉS" gomb |
| `error` | Hibaüzenet kártya |

Az AppBar-ban **⚙️ Beállítások** gomb nyitja meg a `SettingsPage`-t.  
A mérés után az eredmény bekerül a session-szintű **előzmények** listájába (max 10 látható).

Az oldal alján **referencia anyagpár** lista is megjelenik összehasonlításhoz.

```dart
// Beállítások alkalmazása mérésindításkor:
_collector.startCollection(
  dataIntervalMs:   widget.settings.samplingIntervalMs,
  timeoutMs:        widget.settings.timeoutMs,
  stopConfirmCount: widget.settings.stopConfirmCount,
);
```

---

### SettingsPage

`lib/pages/settings_page.dart`

`SliverAppBar.large`-alapú oldal, `ChoiceChip` gombok az opciók kiválasztásához.

```dart
// Megnyitás a MeasurementPage-ről:
await Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => SettingsPage(settings: widget.settings)),
);
```

Gombok:
- **Mentés** → eltárolja az összes értéket és visszalép
- **↺ Visszaállítás** (AppBar jobb szélén) → megerősítő dialóg után alapértékekre állít

---

### DevPage

`lib/pages/dev_page.dart`

Valós idejű szenzor megjelenítés. Rögzítés indítása/leállítása gombbal.

**3 grafikon** jelenik meg egymás alatt (20 ms mintavételezéssel):

| Grafikon | Szenzor | Egység |
|---|---|---|
| User Accelerometer | `userAccelerometerEventStream` (gravitáció nélkül) | m/s² |
| Raw Accelerometer | `accelerometerEventStream` (gravitációval) | m/s² |
| Gyroscope | `gyroscopeEventStream` | rad/s |

A megjelenített minták száma (`devMaxSamples`) beállítható a Beállítások oldalon.

```dart
int get _maxSamples => widget.settings.devMaxSamples;
// ...
if (_accelData.length > _maxSamples) _accelData.removeAt(0);
```

---

### Widgetek

#### `ResultCard`

Megjeleníti a `MeasurementResult` főbb adatait:
- μ értéke + szöveges minősítés (`muEvaluation`)
- Átlagos lassulás (m/s²), total minta, fázisok mintaszáma
- Keret színe μ-arányos (`muColor`)

#### `AccelChart` (`fl_chart`)

Y-tengely gyorsulás az idő függvényében, a mért `rawYData` alapján. X tengely: idő (s), feltételezve a beállított `samplingIntervalMs`-t (20 Hz esetén 0.05 s/minta).

#### `mu_helpers.dart`

```dart
Color muColor(double mu) {
  if (mu < 0.2) return Colors.red;        // nagyon síkos
  if (mu < 0.4) return Colors.orange;
  if (mu < 0.6) return Colors.amber;
  if (mu < 0.8) return Colors.lightGreen;
  return Colors.green;                    // kiváló tapadás
}

String muEvaluation(double mu) {
  if (mu < 0.2) return 'Nagyon síkos (< 0.2)';
  if (mu < 0.4) return 'Síkos (0.2–0.4)';
  if (mu < 0.6) return 'Közepes (0.4–0.6)';
  if (mu < 0.8) return 'Jó tapadás (0.6–0.8)';
  return 'Kiváló (> 0.8)';
}
```

---

## Beállítások

A `SettingsPage` a következő paramétereket teszi beállíthatóvá:

### Adatgyűjtés

- **Mintavételezési idő** – milyen sűrűn mentse el a gyorsulásmérő adatait (20 / 50 / 100 ms). Kisebb érték = több pont, pontosabb görbe, nagyobb adatmennyiség.
- **Max. mérési idő** – biztonsági timeout (5 / 8 / 10 / 15 s). Ha a telefon nem áll meg előbb, ennyi idő után automatikusan befejezi a gyűjtést.
- **Megállás érzékenység** – hány egymást követő 100 ms-es ablaknak kell „csendesnek" lennie (3 / 6 / 10). Kisebb = gyorsabban detektál megállást, de esetleg idő előtt.

### Dev nézet

- **Grafikon minták száma** – a Dev oldal görgetőablakának mérete (100 / 200 / 500 db).

### Mentés

- **Automatikus mentés** – ha be van kapcsolva, a jövőbeli mentési logika automatikusan naplóz (jelenleg flag-et tárol, az integráció a `autoSave` getterrel végezhető el).

---

## Referencia anyagpárok

| Anyagpár | μ |
|---|---|
| 🚗 Gumi – Száraz aszfalt | 0.80 |
| 🏗️ Gumi – Beton | 0.70 |
| 🌧️ Gumi – Nedves aszfalt | 0.50 |
| 👞 Bőr – Fa | 0.50 |
| 🪵 Fa – Fa | 0.40 |
| 🧊 Gumi – Jég | 0.15 |
| ⚙️ Fém – Fém | 0.15 |
| 🪟 Üveg – Üveg | 0.10 |

---

## Technológiák

| Csomag | Verzió | Felhasználás |
|---|---|---|
| `sensors_plus` | ^6.1.1 | Gyorsulásmérő + giroszkóp olvasás |
| `fl_chart` | ^0.70.2 | Y-tengely grafikon, Dev grafikonok |
| `shared_preferences` | ^2.5.3 | Beállítások perzisztens tárolása |
| `flutter` Material 3 | – | UI, `SliverAppBar`, `ChoiceChip` stb. |

---

*Készítette: Kósa Máté, Hajzer Alexandra, Szántó Dávid, Pongrácz Ádám*