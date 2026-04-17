enum WeightUnit {
  kg(1.0, 'Kg'),
  mar(40.0, 'Mar (40kg)'),
  kharrar(800.0, 'Kharrar (20 Marra)');

  final double kgValue;
  final String label;
  const WeightUnit(this.kgValue, this.label);

  double toKg(double value) => value * kgValue;
  double fromKg(double kg) => kg / kgValue;
}
