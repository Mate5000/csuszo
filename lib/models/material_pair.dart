/// Reference material pair with known friction coefficient.
class MaterialPair {
  final String name;
  final String icon;
  final double mu;

  const MaterialPair({required this.name, required this.icon, required this.mu});
}

const List<MaterialPair> referenceMaterialPairs = [
  MaterialPair(name: 'Jég - Jég', icon: '🧊', mu: 0.03),
  MaterialPair(name: 'Acél - Jég', icon: '⛸️', mu: 0.01),
  MaterialPair(name: 'Fa - Nedves fa', icon: '💧', mu: 0.2),
  MaterialPair(name: 'Acél - Acél', icon: '⚙️', mu: 0.15),
  MaterialPair(name: 'Fa - Fa', icon: '🪵', mu: 0.4),
  MaterialPair(name: 'Bőr - Fa', icon: '👞', mu: 0.5),
  MaterialPair(name: 'Gumi - Beton', icon: '🛞', mu: 0.6),
  MaterialPair(name: 'Gumi - Aszfalt', icon: '🚗', mu: 0.7),
  MaterialPair(name: 'Gumi - Száraz aszfalt', icon: '🏎️', mu: 0.8),
];