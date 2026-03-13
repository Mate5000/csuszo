import React, { useState, useEffect, useRef } from 'react';
import { StyleSheet, View, ScrollView, Dimensions, TouchableOpacity } from 'react-native';
import { Provider as PaperProvider, MD3DarkTheme, Card, Button, Text, Appbar, BottomNavigation } from 'react-native-paper';
import { Accelerometer } from 'expo-sensors';
import { LineChart, BarChart } from 'react-native-chart-kit';

// Egyedi sötét téma
const customDarkTheme = {
  ...MD3DarkTheme,
  colors: {
    ...MD3DarkTheme.colors,
    primary: '#64B5F6',
    primaryContainer: '#1565C0',
    secondary: '#81C784',
    secondaryContainer: '#2E7D32',
    background: '#1A1F2E',
    surface: '#252B3A',
    surfaceVariant: '#2D3447',
  },
};

// Főképernyő - Csúszási mérő
const MeasurementScreen = ({ 
  appPhase, 
  coefficient, 
  accelerationData, 
  isCollectingData,
  onStartMeasurement,
  onReset,
  phaseStats,
  dataCount
}) => {
  const getCardContent = () => {
    switch (appPhase) {
      case 'READY':
        return {
          // title: 'Csúszási Súrlódási Mérő',
          title: 'kell az ötös fizikából',
          description: 'Nyomd meg a gombot és lökd meg a telefont egy sima felületen!',
        };
      case 'MEASURING':
        return {
          title: 'Mérés Folyamatban...',
          description: `Csúszás észlelése... (${dataCount} adat)`,
        };
      case 'RESULT':
        return {
          title: 'Eredmény',
          description: 'Csúszási súrlódási együttható',
        };
      default:
        return { title: '', description: '' };
    }
  };

  const content = getCardContent();

  return (
    <View style={styles.screenContainer}>
      <Card style={styles.card} elevation={5}>
        <Card.Content style={styles.cardContent}>
          <Text variant="headlineLarge" style={styles.title}>
            {content.title}
          </Text>
          
          <Text variant="bodyLarge" style={styles.description}>
            {content.description}
          </Text>

          {appPhase === 'READY' && (
            <TouchableOpacity
              style={styles.startButton}
              onPress={onStartMeasurement}
              activeOpacity={0.7}
              hitSlop={{ top: 20, bottom: 20, left: 20, right: 20 }}
            >
              <Text style={styles.startButtonText}>▶  MÉRÉS INDÍTÁSA</Text>
            </TouchableOpacity>
          )}

          {appPhase === 'MEASURING' && (
            <View style={styles.measuringContainer}>
              <View style={styles.pulseCircle}>
                <Text style={styles.pulseText}>📊</Text>
              </View>
              <Text style={styles.measuringText}>Várakozás a megállásra...</Text>
            </View>
          )}

          {appPhase === 'RESULT' && (
            <View style={styles.resultContainer}>
              <View style={styles.coefficientDisplay}>
                <Text variant="displaySmall" style={styles.coefficientLabel}>
                  μ =
                </Text>
                <Text variant="displayLarge" style={styles.coefficientValue}>
                  {coefficient.toFixed(2)}
                </Text>
              </View>

              <Card style={styles.debugCard} elevation={2}>
                <Card.Content>
                  <Text variant="titleSmall" style={styles.debugTitle}>
                    Mérési adatok
                  </Text>
                  <Text style={styles.debugInfoText}>
                    Összes adat: {accelerationData.length}
                  </Text>
                  <Text style={styles.debugInfoText}>
                    Gyorsulás: {phaseStats.acceleration} adat
                  </Text>
                  <Text style={styles.debugInfoText}>
                    Egyenletes: {phaseStats.steady} adat
                  </Text>
                  <Text style={styles.debugInfoText}>
                    Lassulás: {phaseStats.deceleration} adat
                  </Text>
                  
                  {phaseStats.deceleration < 5 && (
                    <Text style={styles.warningText}>
                      Kevés lassulási adat! Lökd meg erősebben!
                    </Text>
                  )}
                </Card.Content>
              </Card>
              
              <TouchableOpacity
                style={styles.resetButtonTouchable}
                onPress={onReset}
                activeOpacity={0.7}
                hitSlop={{ top: 15, bottom: 15, left: 15, right: 15 }}
              >
                <Text style={styles.resetButtonText}>🔄  ÚJ MÉRÉS</Text>
              </TouchableOpacity>
            </View>
          )}
        </Card.Content>
      </Card>
    </View>
  );
};

// Dev menü képernyő
const DevMenuScreen = ({ accelerationData, realtimeSensorData, realtimeHistory }) => {
  const screenWidth = Dimensions.get('window').width - 40;

  const getChartData = () => {
    if (accelerationData.length === 0) {
      return { labels: ['0'], datasets: [{ data: [0] }] };
    }
    const maxPoints = 50;
    const step = Math.ceil(accelerationData.length / maxPoints);
    const sampledData = accelerationData.filter((_, index) => index % step === 0);
    return {
      labels: sampledData.map((_, index) => (index * step * 0.05).toFixed(1)),
      datasets: [{
        data: sampledData.length > 0 ? sampledData : [0],
        color: (opacity = 1) => `rgba(100, 181, 246, ${opacity})`,
        strokeWidth: 2
      }]
    };
  };

  const getRealtimeChartData = () => {
    if (realtimeHistory.length === 0) {
      return {
        labels: [''],
        datasets: [
          { data: [0], color: (opacity = 1) => `rgba(100, 181, 246, ${opacity})` },
          { data: [0], color: (opacity = 1) => `rgba(129, 199, 132, ${opacity})` },
          { data: [0], color: (opacity = 1) => `rgba(255, 183, 77, ${opacity})` }
        ],
        legend: ['X', 'Y', 'Z']
      };
    }
    const last20 = realtimeHistory.slice(-20);
    return {
      labels: last20.map((_, i) => i % 5 === 0 ? i.toString() : ''),
      datasets: [
        { data: last20.map(d => d.x), color: (opacity = 1) => `rgba(100, 181, 246, ${opacity})`, strokeWidth: 2 },
        { data: last20.map(d => d.y), color: (opacity = 1) => `rgba(129, 199, 132, ${opacity})`, strokeWidth: 2 },
        { data: last20.map(d => d.z), color: (opacity = 1) => `rgba(255, 183, 77, ${opacity})`, strokeWidth: 2 }
      ],
      legend: ['X', 'Y', 'Z']
    };
  };

  const getStatsBarChartData = () => {
    if (accelerationData.length === 0) {
      return { labels: ['Min', 'Átlag', 'Max'], datasets: [{ data: [0, 0, 0] }] };
    }
    const min = Math.min(...accelerationData);
    const max = Math.max(...accelerationData);
    const avg = accelerationData.reduce((a, b) => a + b, 0) / accelerationData.length;
    return {
      labels: ['Min', 'Átlag', 'Max'],
      datasets: [{ data: [Math.abs(min), Math.abs(avg), Math.abs(max)] }]
    };
  };

  return (
    <ScrollView 
      style={styles.screenContainer}
      contentContainerStyle={styles.scrollContent}
      showsVerticalScrollIndicator={true}
      bounces={true}
      nestedScrollEnabled={true}
    >
      <Card style={styles.devCard} elevation={3}>
        <Card.Title title="Valós idejű szenzor adatok" titleStyle={styles.cardTitle} />
        <Card.Content>
          <View style={styles.sensorDataRow}>
            <Text style={styles.sensorLabel}>X tengely:</Text>
            <Text style={styles.sensorValue}>{realtimeSensorData.x.toFixed(3)} g</Text>
          </View>
          <View style={styles.sensorDataRow}>
            <Text style={styles.sensorLabel}>Y tengely:</Text>
            <Text style={styles.sensorValue}>{realtimeSensorData.y.toFixed(3)} g</Text>
          </View>
          <View style={styles.sensorDataRow}>
            <Text style={styles.sensorLabel}>Z tengely:</Text>
            <Text style={styles.sensorValue}>{realtimeSensorData.z.toFixed(3)} g</Text>
          </View>
          <View style={styles.chartContainer}>
            <Text style={styles.chartTitle}>Valós idejű grafikon (XYZ)</Text>
            <LineChart
              data={getRealtimeChartData()}
              width={screenWidth - 60}
              height={200}
              chartConfig={{
                backgroundColor: '#252B3A',
                backgroundGradientFrom: '#252B3A',
                backgroundGradientTo: '#2D3447',
                decimalPlaces: 2,
                color: (opacity = 1) => `rgba(176, 190, 197, ${opacity})`,
                labelColor: (opacity = 1) => `rgba(176, 190, 197, ${opacity})`,
                style: { borderRadius: 16 },
                propsForDots: { r: '1' }
              }}
              withInnerLines={false}
              withOuterLines={true}
              style={styles.chart}
            />
          </View>
        </Card.Content>
      </Card>

      <Card style={styles.devCard} elevation={3}>
        <Card.Title title="Utolsó mérés adatai" titleStyle={styles.cardTitle} />
        <Card.Content>
          <Text style={styles.infoText}>Rögzített adatpontok: {accelerationData.length}</Text>
          <Text style={styles.infoText}>Mintavételi frekvencia: 20 Hz (50ms)</Text>
          {accelerationData.length > 0 && (
            <View style={styles.chartContainer}>
              <Text style={styles.chartTitle}>Y tengely gyorsulás (g)</Text>
              <LineChart
                data={getChartData()}
                width={screenWidth - 60}
                height={220}
                chartConfig={{
                  backgroundColor: '#252B3A',
                  backgroundGradientFrom: '#252B3A',
                  backgroundGradientTo: '#2D3447',
                  decimalPlaces: 2,
                  color: (opacity = 1) => `rgba(100, 181, 246, ${opacity})`,
                  labelColor: (opacity = 1) => `rgba(176, 190, 197, ${opacity})`,
                  style: { borderRadius: 16 },
                  propsForDots: { r: '2', strokeWidth: '1', stroke: '#64B5F6' }
                }}
                bezier
                style={styles.chart}
              />
              <Text style={styles.chartXLabel}>Idő (s)</Text>
            </View>
          )}
          {accelerationData.length === 0 && (
            <Text style={styles.noDataText}>Még nem történt mérés.</Text>
          )}
        </Card.Content>
      </Card>

      <Card style={styles.devCard} elevation={3}>
        <Card.Title title="Statisztikák" titleStyle={styles.cardTitle} />
        <Card.Content>
          {accelerationData.length > 0 ? (
            <>
              <View style={styles.sensorDataRow}>
                <Text style={styles.sensorLabel}>Minimum (Y):</Text>
                <Text style={styles.sensorValue}>{Math.min(...accelerationData).toFixed(3)} g</Text>
              </View>
              <View style={styles.sensorDataRow}>
                <Text style={styles.sensorLabel}>Maximum (Y):</Text>
                <Text style={styles.sensorValue}>{Math.max(...accelerationData).toFixed(3)} g</Text>
              </View>
              <View style={styles.sensorDataRow}>
                <Text style={styles.sensorLabel}>Átlag (Y):</Text>
                <Text style={styles.sensorValue}>
                  {(accelerationData.reduce((a, b) => a + b, 0) / accelerationData.length).toFixed(3)} g
                </Text>
              </View>
              <View style={styles.chartContainer}>
                <Text style={styles.chartTitle}>Statisztikai oszlopdiagram</Text>
                <BarChart
                  data={getStatsBarChartData()}
                  width={screenWidth - 60}
                  height={200}
                  chartConfig={{
                    backgroundColor: '#252B3A',
                    backgroundGradientFrom: '#252B3A',
                    backgroundGradientTo: '#2D3447',
                    decimalPlaces: 2,
                    color: (opacity = 1) => `rgba(129, 199, 132, ${opacity})`,
                    labelColor: (opacity = 1) => `rgba(176, 190, 197, ${opacity})`,
                    style: { borderRadius: 16 }
                  }}
                  style={styles.chart}
                  showValuesOnTopOfBars={true}
                />
              </View>
            </>
          ) : (
            <Text style={styles.noDataText}>Nincs elérhető statisztika</Text>
          )}
        </Card.Content>
      </Card>
    </ScrollView>
  );
};

export default function App() {
  const [appPhase, setAppPhase] = useState('READY');
  const [coefficient, setCoefficient] = useState(0.0);
  const [accelerationData, setAccelerationData] = useState([]);
  const [isCollectingData, setIsCollectingData] = useState(false);
  const [realtimeSensorData, setRealtimeSensorData] = useState({ x: 0, y: 0, z: 0 });
  const [realtimeHistory, setRealtimeHistory] = useState([]);
  
  // Refs a gyors szenzor adatok tárolására (nem okoz re-rendert)
  const sensorDataRef = useRef({ x: 0, y: 0, z: 0 });
  const historyRef = useRef([]);
  const uiUpdateIntervalRef = useRef(null);
  const [phaseStats, setPhaseStats] = useState({ acceleration: 0, steady: 0, deceleration: 0 });
  const [dataCount, setDataCount] = useState(0);
  const [index, setIndex] = useState(0);
  
  // Refs
  const measurementSubscriptionRef = useRef(null);
  const realtimeSubscriptionRef = useRef(null);
  const measurementTimeoutRef = useRef(null);
  const detectionIntervalRef = useRef(null);
  const collectedDataRef = useRef([]);
  const hasMovedRef = useRef(false);
  const stoppedCounterRef = useRef(0);

  // Valós idejű monitoring - optimalizált build-hez
  useEffect(() => {
    // Szenzor gyorsan frissül, de csak ref-be ment (nem okoz re-rendert)
    Accelerometer.setUpdateInterval(16); // ~60Hz szenzor olvasás
    
    realtimeSubscriptionRef.current = Accelerometer.addListener(data => {
      // Csak ref-be mentjük - nincs React re-render!
      sensorDataRef.current = { x: data.x, y: data.y, z: data.z };
      historyRef.current = [...historyRef.current, { x: data.x, y: data.y, z: data.z }].slice(-50);
    });
    
    // UI frissítés külön intervallummal (200ms = 5fps a UI-nak elég)
    uiUpdateIntervalRef.current = setInterval(() => {
      setRealtimeSensorData({ ...sensorDataRef.current });
      setRealtimeHistory([...historyRef.current]);
    }, 200);

    return () => {
      if (realtimeSubscriptionRef.current) {
        realtimeSubscriptionRef.current.remove();
      }
      if (uiUpdateIntervalRef.current) {
        clearInterval(uiUpdateIntervalRef.current);
      }
      cleanupMeasurement();
    };
  }, []);

  const cleanupMeasurement = () => {
    if (measurementSubscriptionRef.current) {
      measurementSubscriptionRef.current.remove();
      measurementSubscriptionRef.current = null;
    }
    if (measurementTimeoutRef.current) {
      clearTimeout(measurementTimeoutRef.current);
      measurementTimeoutRef.current = null;
    }
    if (detectionIntervalRef.current) {
      clearInterval(detectionIntervalRef.current);
      detectionIntervalRef.current = null;
    }
  };

  const finishMeasurement = () => {
    console.log('=== MÉRÉS BEFEJEZÉSE ===');
    cleanupMeasurement();
    
    const data = [...collectedDataRef.current];
    console.log('Összegyűjtött adatok:', data.length);
    
    setIsCollectingData(false);
    calculateFrictionCoefficient(data);
    setAppPhase('RESULT');
  };

  const onStartMeasurement = () => {
    console.log('=== MÉRÉS INDÍTÁSA ===');
    
    // Reset
    collectedDataRef.current = [];
    hasMovedRef.current = false;
    stoppedCounterRef.current = 0;
    setDataCount(0);
    setAppPhase('MEASURING');
    setIsCollectingData(true);
    
    // Accelerometer indítása - gyorsabb mintavételezés a build-elt verzióhoz
    Accelerometer.setUpdateInterval(16); // ~60Hz szenzor olvasás
    
    let lastDataTime = 0;
    let lastUiTime = 0;
    
    measurementSubscriptionRef.current = Accelerometer.addListener(data => {
      const now = Date.now();
      
      // Adatgyűjtés: ~50ms-ként (20Hz) - ez nem okoz re-rendert
      if (now - lastDataTime >= 50) {
        collectedDataRef.current.push(data.y);
        lastDataTime = now;
      }
      
      // UI frissítés: csak 300ms-ként - ez okoz re-rendert
      if (now - lastUiTime >= 300) {
        setDataCount(collectedDataRef.current.length);
        lastUiTime = now;
      }
    });
    
    // Maximum idő (biztonsági határ)
    measurementTimeoutRef.current = setTimeout(() => {
      console.log('Maximum mérési idő elérve');
      finishMeasurement();
    }, 8000);
    
    // Megállás detektálás
    detectionIntervalRef.current = setInterval(() => {
      const data = collectedDataRef.current;
      
      if (data.length < 20) return;
      
      const lastValues = data.slice(-10);
      const avgAbs = lastValues.reduce((sum, v) => sum + Math.abs(v), 0) / lastValues.length;
      const maxAbs = Math.max(...lastValues.map(v => Math.abs(v)));
      
      // Mozgás detektálás
      if (!hasMovedRef.current && maxAbs > 0.2) {
        hasMovedRef.current = true;
        console.log('Mozgás észlelve!');
      }
      
      // Megállás detektálás (csak ha volt mozgás)
      if (hasMovedRef.current) {
        if (avgAbs < 0.1 && maxAbs < 0.15) {
          stoppedCounterRef.current++;
          console.log(`Megállás: ${stoppedCounterRef.current}/6`);
          
          if (stoppedCounterRef.current >= 6) {
            console.log('Telefon megállt!');
            finishMeasurement();
          }
        } else {
          stoppedCounterRef.current = 0;
        }
      }
    }, 100);
  };

  const calculateFrictionCoefficient = (data) => {
    if (!data || data.length === 0) {
      console.log('Nincs adat!');
      setCoefficient(0.0);
      setAccelerationData([]);
      return;
    }

    const g = 9.81;
    const accelerationsMS2 = data.map(y => y * g);
    
    const accelerationThreshold = 2.0;
    const steadyThreshold = 1.5;
    const decelerationThreshold = 1.5;
    
    const accelerationPhase = [];
    const steadyPhase = [];
    const decelerationPhase = [];
    
    for (let i = 0; i < accelerationsMS2.length; i++) {
      const value = accelerationsMS2[i];
      const absValue = Math.abs(value);
      
      if (value > accelerationThreshold) {
        accelerationPhase.push({ index: i, value });
      } else if (value < -decelerationThreshold) {
        decelerationPhase.push({ index: i, value });
      } else if (absValue < steadyThreshold) {
        steadyPhase.push({ index: i, value });
      }
    }
    
    setPhaseStats({
      acceleration: accelerationPhase.length,
      steady: steadyPhase.length,
      deceleration: decelerationPhase.length
    });
    
    if (decelerationPhase.length < 3) {
      console.log('Nincs elég lassulási adat!');
      setCoefficient(0.0);
      setAccelerationData(data);
      return;
    }
    
    const decelerationValues = decelerationPhase.map(d => Math.abs(d.value));
    const avgDeceleration = decelerationValues.reduce((sum, v) => sum + v, 0) / decelerationValues.length;
    const mu = avgDeceleration / g;
    
    console.log(`Súrlódási együttható: ${mu.toFixed(3)}`);
    setCoefficient(mu);
    setAccelerationData(data);
  };

  const onReset = () => {
    console.log('Reset');
    cleanupMeasurement();
    setAppPhase('READY');
    setCoefficient(0.0);
    setAccelerationData([]);
    setIsCollectingData(false);
    setDataCount(0);
    collectedDataRef.current = [];
    hasMovedRef.current = false;
    stoppedCounterRef.current = 0;
  };

  const routes = [
    { key: 'measurement', title: 'Mérés', focusedIcon: 'speedometer', unfocusedIcon: 'speedometer-slow' },
    { key: 'dev', title: 'Dev Menü', focusedIcon: 'developer-board', unfocusedIcon: 'developer-board' },
  ];

  const renderScene = ({ route }) => {
    switch (route.key) {
      case 'measurement':
        return (
          <MeasurementScreen
            appPhase={appPhase}
            coefficient={coefficient}
            accelerationData={accelerationData}
            isCollectingData={isCollectingData}
            onStartMeasurement={onStartMeasurement}
            onReset={onReset}
            phaseStats={phaseStats}
            dataCount={dataCount}
          />
        );
      case 'dev':
        return (
          <DevMenuScreen 
            accelerationData={accelerationData}
            realtimeSensorData={realtimeSensorData}
            realtimeHistory={realtimeHistory}
          />
        );
      default:
        return null;
    }
  };

  return (
    <PaperProvider theme={customDarkTheme}>
      <View style={styles.container}>
        <Appbar.Header style={styles.appbar}>
          <Appbar.Content title="Csúszási Súrlódás Mérő" titleStyle={styles.appbarTitle} />
        </Appbar.Header>
        
        <BottomNavigation
          navigationState={{ index, routes }}
          onIndexChange={setIndex}
          renderScene={renderScene}
          barStyle={styles.bottomNav}
          activeColor="#64B5F6"
          inactiveColor="#607D8B"
        />
      </View>
    </PaperProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1A1F2E',
  },
  appbar: {
    backgroundColor: '#252B3A',
    elevation: 4,
  },
  appbarTitle: {
    color: '#64B5F6',
    fontWeight: 'bold',
  },
  bottomNav: {
    backgroundColor: '#252B3A',
  },
  screenContainer: {
    flex: 1,
    backgroundColor: '#1A1F2E',
    padding: 20,
  },
  scrollContent: {
    paddingBottom: 40,
  },
  card: {
    backgroundColor: '#252B3A',
    borderRadius: 16,
    marginTop: 20,
  },
  cardContent: {
    padding: 30,
    alignItems: 'center',
  },
  title: {
    color: '#64B5F6',
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 20,
  },
  description: {
    color: '#B0BEC5',
    textAlign: 'center',
    marginBottom: 40,
    lineHeight: 24,
  },
  startButton: {
    backgroundColor: '#1565C0',
    paddingVertical: 22,
    paddingHorizontal: 50,
    borderRadius: 35,
    marginTop: 20,
    minWidth: 250,
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
  },
  startButtonText: {
    color: '#FFFFFF',
    fontSize: 20,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  measuringContainer: {
    alignItems: 'center',
    marginTop: 20,
  },
  pulseCircle: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: '#1565C0',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 20,
  },
  pulseText: {
    fontSize: 40,
  },
  measuringText: {
    color: '#B0BEC5',
    fontSize: 16,
  },
  resultContainer: {
    marginTop: 20,
    width: '100%',
    alignItems: 'center',
  },
  coefficientDisplay: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 20,
    gap: 10,
  },
  coefficientLabel: {
    color: '#64B5F6',
    fontWeight: 'bold',
  },
  coefficientValue: {
    color: '#81C784',
    fontWeight: 'bold',
    fontSize: 56,
  },
  debugCard: {
    backgroundColor: '#2D3447',
    borderRadius: 8,
    marginTop: 15,
    marginBottom: 15,
    width: '100%',
  },
  debugTitle: {
    color: '#64B5F6',
    fontWeight: 'bold',
    marginBottom: 10,
  },
  debugInfoText: {
    color: '#B0BEC5',
    fontSize: 13,
    marginBottom: 5,
  },
  warningText: {
    color: '#FFB74D',
    fontSize: 12,
    marginTop: 10,
    fontStyle: 'italic',
  },
  resetButton: {
    marginTop: 10,
    width: '100%',
  },
  resetButtonTouchable: {
    backgroundColor: '#1565C0',
    paddingVertical: 18,
    paddingHorizontal: 40,
    borderRadius: 30,
    marginTop: 15,
    width: '100%',
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 5,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
  },
  resetButtonText: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  devCard: {
    backgroundColor: '#252B3A',
    borderRadius: 12,
    marginBottom: 16,
  },
  cardTitle: {
    color: '#64B5F6',
    fontWeight: 'bold',
  },
  sensorDataRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#2D3447',
  },
  sensorLabel: {
    color: '#B0BEC5',
    fontSize: 16,
  },
  sensorValue: {
    color: '#81C784',
    fontSize: 16,
    fontWeight: 'bold',
    fontFamily: 'monospace',
  },
  infoText: {
    color: '#B0BEC5',
    fontSize: 14,
    marginBottom: 8,
  },
  chartContainer: {
    marginTop: 20,
    alignItems: 'center',
  },
  chartTitle: {
    color: '#64B5F6',
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  chart: {
    marginVertical: 8,
    borderRadius: 16,
  },
  chartXLabel: {
    color: '#B0BEC5',
    fontSize: 12,
    marginTop: 5,
  },
  noDataText: {
    color: '#607D8B',
    fontSize: 14,
    fontStyle: 'italic',
    textAlign: 'center',
    marginTop: 10,
  },
});