class Station {
  final String name;
  final double latitude;
  final double longitude;

  Station({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  // == operatörünü override et
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Station && other.name == name;
  }

  // hashCode'u override et
  @override
  int get hashCode => name.hashCode;

  void get position {}

  void get location {}

  // toString metodu ekleyelim (debug için kullanışlıdır)
  @override
  String toString() => name;
}
