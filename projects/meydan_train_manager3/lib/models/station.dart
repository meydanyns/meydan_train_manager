class Station {
  final String name;
  final double latitude;
  final double longitude;

  Station({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Station && other.name == name);

  @override
  int get hashCode => name.hashCode;
}
