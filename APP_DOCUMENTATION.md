# Csúszási Súrlódás Mérő App - Teljes Dokumentáció Flutter Implementációhoz

## 📱 App Áttekintés

Ez egy műszeres fizikai mérőalkalmazás, amely a telefon beépített accelerométerét használva méri a **csúszási súrlódási együtthatót (μ)** különböző felületeken.

### Fő Funkciók
- ✅ Valós idejű accelerométer adatok megjelenítése
- ✅ Automatikus mozgás és megállás detektálás
- ✅ Csúszási súrlódási együttható számítása
- ✅ Grafikus adatvizualizáció (vonaldiagram, oszlopdiagram)
- ✅ Fejlesztői debug panel részletes adatokkal
- ✅ Material Design alapú, sötét téma UI

---

## 🎨 UI/UX Specifikáció - Material Design

### Szín Paletta (Dark Theme)

```dart
// Egyedi sötét téma színek
final ThemeData customDarkTheme = ThemeData.dark().copyWith(
  colorScheme: ColorScheme.dark(
    primary: Color(0xFF64B5F6),           // Világoskék - fő akciógombok
    primaryContainer: Color(0xFF1565C0),  // Sötét kék - gomb háttér
    secondary: Color(0xFF81C784),         // Világoszöld - siker/eredmény
    secondaryContainer: Color(0xFF2E7D32),// Sötét zöld
    background: Color(0xFF1A1F2E),        // Háttér - sötét navy
    surface: Color(0xFF252B3A),           // Kártya felület - világosabb navy
    surfaceVariant: Color(0xFF2D3447),    // Debug panel - még világosabb
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF252B3A),
    elevation: 4.0,
    titleTextStyle: TextStyle(
      color: Color(0xFF64B5F6),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
);
```

### Font Rendszer

```dart
// Címsor
headlineLarge: TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: Color(0xFF64B5F6),  // primary
)

// Leírás
bodyLarge: TextStyle(
  fontSize: 16,
  color: Color(0xFFB0BEC5),  // szürke
  height: 1.5,
)

// Eredmény szám (μ érték)
displayLarge: TextStyle(
  fontSize: 56,
  fontWeight: FontWeight.bold,
  color: Color(0xFF81C784),  // secondary (zöld)
)

// Debug info
bodySmall: TextStyle(
  fontSize: 13,
  color: Color(0xFFB0BEC5),
  fontFamily: 'monospace',
)
```

### Spacing és Layout

```dart
// Általános padding
const double standardPadding = 20.0;
const double cardPadding = 30.0;

// Margók
const double cardMarginTop = 20.0;
const double elementSpacing = 20.0;

// Border radius
const double cardRadius = 16.0;
const double buttonRadius = 35.0;

// Elevation (árnyék)
const double cardElevation = 5.0;
const double buttonElevation = 5.0;
```

---

## 🏗️ App Architektúra

### 1. Képernyő Struktúra

```
App Root
├── AppBar (felső sáv)
│   └── "Csúszási Súrlódás Mérő"
│
└── BottomNavigationBar (alsó navigáció)
    ├── Tab 1: Mérés Képernyő (MeasurementScreen)
    └── Tab 2: Dev Menü (DevMenuScreen)
```

### 2. State Management Struktúra

```dart
class AppState {
  // Mérés állapot
  AppPhase appPhase;              // 'READY' | 'MEASURING' | 'RESULT'
  double coefficient;             // μ érték (0.0 - 2.0)
  List<double> accelerationData;  // Gyűjtött Y tengely adatok
  bool isCollectingData;          // Folyamatban van-e mérés
  
  // Valós idejű adatok
  SensorData realtimeSensorData;  // { x, y, z } - aktuális értékek
  List<SensorData> realtimeHistory; // Utolsó 50 adat grafikon számára
  
  // Statisztikák
  PhaseStats phaseStats;          // { acceleration, steady, deceleration }
  int dataCount;                  // Hány adat gyűlt össze eddig
  
  // Refs (nem UI state, csak belső változók)
  Timer? measurementTimer;
  StreamSubscription? sensorSubscription;
  List<double> collectedDataBuffer;
  bool hasMovedFlag;
  int stoppedCounter;
}
```

---

## 📐 Részletes Képernyő Layoutok

### 1. Mérés Képernyő (Measurement Screen)

```
┌─────────────────────────────────────────┐
│  AppBar: "Csúszási Súrlódás Mérő"       │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐  │
│  │                                   │  │
│  │  Card (elevation: 5)              │  │
│  │                                   │  │
│  │   [CÍMSOR - headlineLarge]        │  │
│  │   "kell az ötös fizikából"        │  │
│  │                                   │  │
│  │   [LEÍRÁS - bodyLarge]            │  │
│  │   "Nyomd meg a gombot..."         │  │
│  │                                   │  │
│  │   ┌─────────────────────────┐     │  │
│  │   │  ▶ MÉRÉS INDÍTÁSA       │     │  │
│  │   │  (nagy kék gomb)        │     │  │
│  │   └─────────────────────────┘     │  │
│  │                                   │  │
│  └───────────────────────────────────┘  │
│                                         │
├─────────────────────────────────────────┤
│  BottomNavigationBar                    │
│  [Mérés] [Dev Menü]                     │
└─────────────────────────────────────────┘
```

#### 1.1. READY állapot UI

```dart
Widget buildReadyState() {
  return Card(
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: EdgeInsets.all(30),
      child: Column(
        children: [
          // Címsor
          Text(
            'kell az ötös fizikából',
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          
          // Leírás
          Text(
            'Nyomd meg a gombot és lökd meg a telefont egy sima felületen!',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          
          // Start gomb
          ElevatedButton(
            onPressed: onStartMeasurement,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1565C0),
              padding: EdgeInsets.symmetric(vertical: 22, horizontal: 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(35),
              ),
              elevation: 5,
              minimumSize: Size(250, 0),
            ),
            child: Text(
              '▶  MÉRÉS INDÍTÁSA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

#### 1.2. MEASURING állapot UI

```
┌───────────────────────────────────┐
│  Mérés Folyamatban...             │
│                                   │
│  Csúszás észlelése... (45 adat)   │
│                                   │
│       ╭─────────╮                 │
│       │   📊    │  ← pulzáló      │
│       ╰─────────╯     animáció    │
│                                   │
│  Várakozás a megállásra...        │
└───────────────────────────────────┘
```

```dart
Widget buildMeasuringState() {
  return Column(
    children: [
      Text(
        'Mérés Folyamatban...',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      SizedBox(height: 20),
      
      Text(
        'Csúszás észlelése... ($dataCount adat)',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      SizedBox(height: 40),
      
      // Pulzáló kör animáció
      AnimatedContainer(
        duration: Duration(milliseconds: 800),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF1565C0),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF1565C0).withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '📊',
            style: TextStyle(fontSize: 40),
          ),
        ),
      ),
      SizedBox(height: 20),
      
      Text(
        'Várakozás a megállásra...',
        style: TextStyle(color: Color(0xFFB0BEC5)),
      ),
    ],
  );
}
```

#### 1.3. RESULT állapot UI

```
┌───────────────────────────────────┐
│  Eredmény                         │
│  Csúszási súrlódási együttható    │
│                                   │
│       μ =  0.22                   │
│       ↑     ↑                     │
│     kék   zöld, nagy              │
│                                   │
│  ┌─────────────────────────────┐  │
│  │ Mérési adatok               │  │
│  │ Összes adat: 78             │  │
│  │ Gyorsulás: 15 adat          │  │
│  │ Egyenletes: 40 adat         │  │
│  │ Lassulás: 23 adat           │  │
│  └─────────────────────────────┘  │
│                                   │
│  ┌─────────────────────────────┐  │
│  │   🔄  ÚJ MÉRÉS              │  │
│  └─────────────────────────────┘  │
└───────────────────────────────────┘
```

```dart
Widget buildResultState() {
  return Column(
    children: [
      // Eredmény címsor
      Text('Eredmény', style: Theme.of(context).textTheme.headlineLarge),
      Text('Csúszási súrlódási együttható'),
      SizedBox(height: 20),
      
      // μ érték megjelenítése
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'μ =',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64B5F6),
            ),
          ),
          SizedBox(width: 10),
          Text(
            coefficient.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Color(0xFF81C784),
            ),
          ),
        ],
      ),
      SizedBox(height: 20),
      
      // Debug info kártya
      Card(
        color: Color(0xFF2D3447),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mérési adatok',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text('Összes adat: ${accelerationData.length}'),
              Text('Gyorsulás: ${phaseStats.acceleration} adat'),
              Text('Egyenletes: ${phaseStats.steady} adat'),
              Text('Lassulás: ${phaseStats.deceleration} adat'),
              
              // Figyelmeztetés kevés adatnál
              if (phaseStats.deceleration < 5)
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Kevés lassulási adat! Lökd meg erősebben!',
                    style: TextStyle(
                      color: Color(0xFFFFB74D),
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      SizedBox(height: 15),
      
      // Új mérés gomb
      ElevatedButton(
        onPressed: onReset,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1565C0),
          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          minimumSize: Size(double.infinity, 0),
        ),
        child: Text(
          '🔄  ÚJ MÉRÉS',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}
```

---

### 2. Dev Menü Képernyő (DevMenuScreen)

```
┌─────────────────────────────────────────┐
│  AppBar: "Csúszási Súrlódás Mérő"       │
├─────────────────────────────────────────┤
│  ScrollView ▼                           │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ Valós idejű szenzor adatok       │  │
│  │                                   │  │
│  │ X tengely:           0.023 g      │  │
│  │ Y tengely:          -0.156 g      │  │
│  │ Z tengely:           0.998 g      │  │
│  │                                   │  │
│  │ [Valós idejű XYZ grafikon]       │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ Utolsó mérés adatai              │  │
│  │                                   │  │
│  │ Rögzített adatpontok: 78          │  │
│  │ Mintavételi frekvencia: 20 Hz     │  │
│  │                                   │  │
│  │ [Y tengely vonaldiagram]          │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ Statisztikák                     │  │
│  │                                   │  │
│  │ [Min/Átlag/Max oszlopdiagram]     │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

#### 2.1. Valós idejű szenzor adatok panel

```dart
Widget buildRealtimeSensorPanel() {
  return Card(
    elevation: 3,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valós idejű szenzor adatok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64B5F6),
            ),
          ),
          SizedBox(height: 16),
          
          // X tengely
          buildSensorRow('X tengely:', realtimeSensorData.x),
          Divider(),
          
          // Y tengely
          buildSensorRow('Y tengely:', realtimeSensorData.y),
          Divider(),
          
          // Z tengely
          buildSensorRow('Z tengely:', realtimeSensorData.z),
          
          SizedBox(height: 20),
          
          // Valós idejű grafikon
          Text('Valós idejű grafikon (XYZ)', style: chartTitleStyle),
          SizedBox(height: 10),
          LineChart(/* 3 vonal: X, Y, Z */),
        ],
      ),
    ),
  );
}

Widget buildSensorRow(String label, double value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 16),
      ),
      Text(
        '${value.toStringAsFixed(3)} g',
        style: TextStyle(
          color: Color(0xFF81C784),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    ],
  );
}
```

#### 2.2. Grafikonok specifikáció

**Vonaldiagram (LineChart) konfiguráció:**

```dart
LineChartData lineChartData = LineChartData(
  backgroundColor: Color(0xFF252B3A),
  gridData: FlGridData(
    show: true,
    drawVerticalLine: false,
    horizontalInterval: 0.5,
    getDrawingHorizontalLine: (value) {
      return FlLine(
        color: Color(0xFF2D3447),
        strokeWidth: 1,
      );
    },
  ),
  titlesData: FlTitlesData(
    bottomTitles: AxisTitles(
      axisNameWidget: Text('Idő (s)', style: labelStyle),
      sideTitles: SideTitles(showTitles: true),
    ),
    leftTitles: AxisTitles(
      axisNameWidget: Text('Gyorsulás (g)', style: labelStyle),
      sideTitles: SideTitles(showTitles: true),
    ),
  ),
  borderData: FlBorderData(show: true),
  lineBarsData: [
    LineChartBarData(
      spots: dataPoints,
      isCurved: true,
      color: Color(0xFF64B5F6),
      barWidth: 2,
      dotData: FlDotData(show: true),
    ),
  ],
);
```

**Oszlopdiagram (BarChart) konfiguráció:**

```dart
BarChartData barChartData = BarChartData(
  backgroundColor: Color(0xFF252B3A),
  barGroups: [
    BarChartGroupData(x: 0, barRods: [
      BarChartRodData(toY: minValue, color: Color(0xFF81C784))
    ]),
    BarChartGroupData(x: 1, barRods: [
      BarChartRodData(toY: avgValue, color: Color(0xFF81C784))
    ]),
    BarChartGroupData(x: 2, barRods: [
      BarChartRodData(toY: maxValue, color: Color(0xFF81C784))
    ]),
  ],
  titlesData: FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          switch (value.toInt()) {
            case 0: return Text('Min');
            case 1: return Text('Átlag');
            case 2: return Text('Max');
            default: return Text('');
          }
        },
      ),
    ),
  ),
);
```

---

## 🧮 Súrlódási Együttható Számítás Algoritmus

### Teljes Folyamat Lépésről Lépésre

```dart
class FrictionCalculator {
  static const double g = 9.81; // m/s²
  
  // Küszöbértékek
  static const double accelerationThreshold = 2.0;   // m/s²
  static const double steadyThreshold = 1.5;         // m/s²
  static const double decelerationThreshold = 1.5;   // m/s²
  
  // Mozgás detektálás
  static const double movementThreshold = 0.2;   // g
  static const double stoppedAvgThreshold = 0.1; // g
  static const double stoppedMaxThreshold = 0.15; // g
  static const int stoppedCountRequired = 6;
  
  static FrictionResult calculate(List<double> rawYData) {
    // 1. KONVERZIÓ: g → m/s²
    List<double> accelerationsMS2 = rawYData.map((y) => y * g).toList();
    
    // 2. FÁZIS OSZTÁLYOZÁS
    List<DataPoint> accelerationPhase = [];
    List<DataPoint> steadyPhase = [];
    List<DataPoint> decelerationPhase = [];
    
    for (int i = 0; i < accelerationsMS2.length; i++) {
      double value = accelerationsMS2[i];
      double absValue = value.abs();
      
      if (value > accelerationThreshold) {
        // POZITÍV > 2 m/s² → GYORSULÁS
        accelerationPhase.add(DataPoint(i, value));
      } else if (value < -decelerationThreshold) {
        // NEGATÍV < -1.5 m/s² → LASSULÁS
        decelerationPhase.add(DataPoint(i, value));
      } else if (absValue < steadyThreshold) {
        // KÖZEL 0 → EGYENLETES
        steadyPhase.add(DataPoint(i, value));
      }
    }
    
    // 3. VALIDÁLÁS
    if (decelerationPhase.length < 3) {
      return FrictionResult(
        coefficient: 0.0,
        isValid: false,
        errorMessage: 'Nincs elég lassulási adat! Lökd meg erősebben!',
        phaseStats: PhaseStats(
          accelerationPhase.length,
          steadyPhase.length,
          decelerationPhase.length,
        ),
      );
    }
    
    // 4. ÁTLAGOS LASSULÁS SZÁMÍTÁSA
    List<double> decelerationValues = decelerationPhase
        .map((dp) => dp.value.abs())
        .toList();
    
    double avgDeceleration = decelerationValues.reduce((a, b) => a + b) /
        decelerationValues.length;
    
    // 5. SÚRLÓDÁSI EGYÜTTHATÓ
    // μ = a / g
    double mu = avgDeceleration / g;
    
    return FrictionResult(
      coefficient: mu,
      isValid: true,
      phaseStats: PhaseStats(
        accelerationPhase.length,
        steadyPhase.length,
        decelerationPhase.length,
      ),
    );
  }
}
```

### Mozgás és Megállás Detektálás

```dart
class MovementDetector {
  bool hasMovedFlag = false;
  int stoppedCounter = 0;
  
  void checkMovement(List<double> recentData) {
    if (recentData.length < 10) return;
    
    List<double> lastValues = recentData.sublist(recentData.length - 10);
    
    double avgAbs = lastValues.map((v) => v.abs())
        .reduce((a, b) => a + b) / lastValues.length;
    double maxAbs = lastValues.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
    
    // MOZGÁS DETEKTÁLÁS
    if (!hasMovedFlag && maxAbs > FrictionCalculator.movementThreshold) {
      hasMovedFlag = true;
      print('✅ Mozgás észlelve! (max: ${maxAbs.toStringAsFixed(3)} g)');
    }
    
    // MEGÁLLÁS DETEKTÁLÁS (csak ha már volt mozgás)
    if (hasMovedFlag) {
      if (avgAbs < FrictionCalculator.stoppedAvgThreshold &&
          maxAbs < FrictionCalculator.stoppedMaxThreshold) {
        stoppedCounter++;
        print('⏸️ Megállás: $stoppedCounter/${FrictionCalculator.stoppedCountRequired}');
        
        if (stoppedCounter >= FrictionCalculator.stoppedCountRequired) {
          print('🛑 Telefon megállt! Mérés befejezése.');
          return true; // Mérés vége
        }
      } else {
        stoppedCounter = 0; // Reset, ha újra mozgást észlelünk
      }
    }
    
    return false;
  }
}
```

---

## 📊 Adatmodell Struktúrák

```dart
// Fő app állapot
enum AppPhase {
  ready,      // Kezdő állapot, várja a start gombot
  measuring,  // Mérés folyamatban
  result,     // Eredmény megjelenítése
}

// Szenzor adat
class SensorData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;
  
  SensorData({
    required this.x,
    required this.y,
    required this.z,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// Fázis statisztika
class PhaseStats {
  final int acceleration;  // Gyorsulási pontok száma
  final int steady;        // Egyenletes mozgás pontok száma
  final int deceleration;  // Lassulási pontok száma
  
  PhaseStats(this.acceleration, this.steady, this.deceleration);
  
  int get total => acceleration + steady + deceleration;
}

// Eredmény objektum
class FrictionResult {
  final double coefficient;
  final bool isValid;
  final String? errorMessage;
  final PhaseStats phaseStats;
  
  FrictionResult({
    required this.coefficient,
    required this.isValid,
    this.errorMessage,
    required this.phaseStats,
  });
}

// Adatpont grafikon számára
class DataPoint {
  final int index;
  final double value;
  
  DataPoint(this.index, this.value);
}
```

---

## 🔄 Mérési Folyamat Részletesen

### 1. Inicializálás (onStartMeasurement)

```dart
void onStartMeasurement() {
  print('🚀 === MÉRÉS INDÍTÁSA ===');
  
  // State reset
  setState(() {
    appPhase = AppPhase.measuring;
    isCollectingData = true;
    dataCount = 0;
  });
  
  // Belső változók reset
  collectedDataBuffer.clear();
  hasMovedFlag = false;
  stoppedCounter = 0;
  
  // Accelerometer konfiguráció
  // 50ms = 20 Hz mintavételezés
  accelerometerEvents(samplingPeriod: Duration(milliseconds: 50))
      .listen((AccelerometerEvent event) {
        // Csak Y tengelyt mentjük (mozgás iránya)
        collectedDataBuffer.add(event.y);
        
        // UI frissítés 300ms-ként (nem minden adatnál)
        if (collectedDataBuffer.length % 6 == 0) {
          setState(() {
            dataCount = collectedDataBuffer.length;
          });
        }
      });
  
  // Maximum idő timeout (8 másodperc)
  measurementTimer = Timer(Duration(seconds: 8), () {
    print('⏱️ Maximum mérési idő elérve');
    finishMeasurement();
  });
  
  // Megállás ellenőrzés 100ms-ként
  Timer.periodic(Duration(milliseconds: 100), (timer) {
    if (checkIfStopped(collectedDataBuffer)) {
      timer.cancel();
      finishMeasurement();
    }
  });
}
```

### 2. Adatgyűjtés Közben

```
┌──────────────────────────────────────────────┐
│  IDŐPONT       Y ÉRTÉK    BESOROLÁS          │
├──────────────────────────────────────────────┤
│  0.00s         0.02g      Nyugalom            │
│  0.05s         0.04g      Nyugalom            │
│  0.10s         0.35g      Gyorsulás kezdete   │
│  0.15s         0.52g      Lökés csúcsa ✓      │
│  0.20s         0.28g      Gyorsulás vége      │
│  0.25s         0.05g      Egyenletes mozgás   │
│  0.30s         0.03g      Egyenletes mozgás   │
│  0.35s        -0.18g      Lassulás kezdete    │
│  0.40s        -0.25g      Súrlódás ✓          │
│  0.45s        -0.22g      Súrlódás ✓          │
│  0.50s        -0.15g      Lassulás vége       │
│  0.55s         0.02g      Megállt (1/6)       │
│  0.60s         0.01g      Megállt (2/6)       │
│  0.65s         0.03g      Megállt (3/6)       │
│  0.70s         0.02g      Megállt (4/6)       │
│  0.75s         0.01g      Megállt (5/6)       │
│  0.80s         0.02g      Megállt (6/6) → STOP│
└──────────────────────────────────────────────┘
```

### 3. Mérés Befejezése

```dart
void finishMeasurement() {
  print('🏁 === MÉRÉS BEFEJEZÉSE ===');
  
  // Timer és listener leállítása
  measurementTimer?.cancel();
  sensorSubscription?.cancel();
  
  // Adat másolása
  List<double> finalData = List.from(collectedDataBuffer);
  print('📊 Összegyűjtött adatok: ${finalData.length}');
  
  // Számítás
  FrictionResult result = FrictionCalculator.calculate(finalData);
  
  // State frissítés
  setState(() {
    appPhase = AppPhase.result;
    isCollectingData = false;
    coefficient = result.coefficient;
    accelerationData = finalData;
    phaseStats = result.phaseStats;
  });
  
  // Log
  print('✅ μ = ${result.coefficient.toStringAsFixed(3)}');
  print('📈 Gyorsulás: ${result.phaseStats.acceleration} pont');
  print('➡️ Egyenletes: ${result.phaseStats.steady} pont');
  print('📉 Lassulás: ${result.phaseStats.deceleration} pont');
}
```

---

## 🎯 Példa Számítás Magyarázattal

### Bemenet (nyers adatok)

```dart
List<double> rawData = [
  0.02,  0.03,  0.04,  // Nyugalomban
  0.35,  0.52,  0.45,  0.28,  // Lökés
  0.05,  0.03,  0.04,  0.02,  // Egyenletes
  -0.18, -0.25, -0.22, -0.20, -0.15,  // Lassulás
  0.02,  0.01,  0.03,  // Megállt
];
```

### Feldolgozás lépések

```dart
// 1. Konverzió g → m/s²
List<double> inMS2 = rawData.map((y) => y * 9.81).toList();
// Eredmény: [0.20, 0.29, 0.39, 3.43, 5.10, 4.41, 2.75, 0.49, ...]

// 2. Osztályozás
for (var value in inMS2) {
  if (value > 2.0) {
    // 3.43, 5.10, 4.41, 2.75 → GYORSULÁS (4 pont)
  } else if (value < -1.5) {
    // -1.77, -2.45, -2.16, -1.96, -1.47 → LASSULÁS (5 pont)
  } else if (value.abs() < 1.5) {
    // többi → EGYENLETES (10 pont)
  }
}

// 3. Lassulási értékek kiszűrése
List<double> decelerations = [1.77, 2.45, 2.16, 1.96, 1.47]; // abszolút értékek

// 4. Átlag számítás
double avg = (1.77 + 2.45 + 2.16 + 1.96 + 1.47) / 5;
// avg = 1.962 m/s²

// 5. Súrlódási együttható
double mu = 1.962 / 9.81;
// mu = 0.20
```

### Eredmény

```
┌────────────────────────────────┐
│         μ = 0.20               │
│                                │
│  Mérési adatok:                │
│  • Összes: 19 adat             │
│  • Gyorsulás: 4 adat           │
│  • Egyenletes: 10 adat         │
│  • Lassulás: 5 adat            │
└────────────────────────────────┘
```

---

## 🔧 Technikai Specifikációk

### Sensorkonfiguráció

```dart
// Accelerometer beállítások
const int samplingRateHz = 20;              // 20 Hz = 50ms
const Duration samplingPeriod = Duration(milliseconds: 50);
const int maxMeasurementSeconds = 8;         // Maximum mérési idő
const int minDataPoints = 20;                // Minimum adatpont a detektáláshoz
```

### Performance Optimalizálás

```dart
// UI frissítési stratégia
const Duration uiUpdateInterval = Duration(milliseconds: 300);
const int uiUpdateBatchSize = 6;  // Minden 6. adatnál frissít (6 × 50ms = 300ms)

// Valós idejű grafikon
const int realtimeHistorySize = 50;  // Utolsó 50 adat
const Duration realtimeUIUpdate = Duration(milliseconds: 200);  // 5 FPS
```

### Memory Management

```dart
// Adatstruktúrák mérete
// - collectedDataBuffer: max 160 elem (8s × 20Hz)
// - realtimeHistory: max 50 elem
// - accelerationData: max 160 elem (eredmény tárolás)
// Összesen: ~370 double (~2.96 KB memória)
```

---

## 📖 Függelék: Fizikai Magyarázat

### Mi történik fizikailag?

```
1. LÖKÉS (t=0s)
   ┌────────┐
   │ TELEFON│─➤  F_lökés
   └────────┘
   
   A telefon gyorsul → pozitív Y érték

2. CSÚSZÁS (t=0.2s)
   ┌────────┐
   │ TELEFON│─➤ v (állandó)
   └────────┘
        ↑
        │ F_súrlódás ≈ 0 (csúszó)
        
   Közel egyenletes mozgás → Y ≈ 0

3. LASSULÁS (t=0.4s)
   ┌────────┐
   │ TELEFON│─➤ v csökken
   └────────┘
        ↑
        │ F_súrlódás (fékez)
        
   Negatív gyorsulás → negatív Y érték

4. MEGÁLLÁS (t=0.8s)
   ┌────────┐
   │ TELEFON│ (v=0)
   └────────┘
   
   Nincs mozgás → Y ≈ 0
```

### Súrlódási erő

```
F_súrlódás = μ × F_nyomó
F_súrlódás = μ × m × g

Newton II. törvénye:
F = m × a

Tehát:
m × a = μ × m × g
a = μ × g
μ = a / g  ← Ez az amit számolunk!
```

### Tipikus értékek

| Felület pár | μ érték | App eredmény |
|-------------|---------|--------------|
| Telefon / üveg asztal | 0.15-0.25 | ✅ Mérhető |
| Telefon / fa asztal | 0.20-0.35 | ✅ Mérhető |
| Telefon / műanyag | 0.30-0.50 | ✅ Mérhető |
| Telefon / szőnyeg | 0.50-0.80 | ⚠️ Gyors megállás |
| Telefon / jég | 0.02-0.05 | ⚠️ Nehéz mérni |

---

## ✅ Implementációs Checklist

### Kötelező funkciók

- [ ] Accelerometer integráció (50ms mintavétel)
- [ ] 3 állapot kezelése (Ready/Measuring/Result)
- [ ] Automatikus mozgás detektálás (>0.2g)
- [ ] Automatikus megállás detektálás (6× <0.1g)
- [ ] Súrlódási együttható számítása (μ = a/g)
- [ ] Fázis osztályozás (gyorsulás/egyenletes/lassulás)
- [ ] Eredmény megjelenítés (μ érték + statisztikák)
- [ ] Új mérés indítása (reset funkció)

### UI elemek

- [ ] Material Design sötét téma
- [ ] AppBar ("Csúszási Súrlódás Mérő")
- [ ] BottomNavigationBar (Mérés / Dev Menü)
- [ ] Start gomb (nagy, kék, kerek)
- [ ] Pulzáló animáció mérés közben
- [ ] μ érték megjelenítés (nagy, zöld szám)
- [ ] Debug info kártya (fázis statisztikák)
- [ ] Új mérés gomb

### Dev Menü

- [ ] Valós idejű XYZ adatok (200ms frissítés)
- [ ] XYZ vonaldiagram (utolsó 50 adat)
- [ ] Y tengely mérési grafikon
- [ ] Min/Átlag/Max oszlopdiagram
- [ ] Rögzített adatpontok száma
- [ ] Mintavételi frekvencia info

### Extra funkciók (opcionális)

- [ ] Mérési előzmények mentése
- [ ] Export CSV formátumban
- [ ] Kalibráció funkció
- [ ] Különböző felületek összehasonlítása
- [ ] Hang/Vibráció feedback
- [ ] Tutorial első indításkor

---

## 📚 Hivatkozások

- Fizika alapok: Newton II. törvény, súrlódás
- Accelerometer API: Flutter sensors package
- Material Design 3: colors, typography, elevation
- Charts: fl_chart package vagy charts_flutter
- State management: Provider vagy Riverpod ajánlott

---

**Verzió:** 1.0  
**Utolsó frissítés:** 2026-03-02  
**Készítette:** Csúszómasó App Team