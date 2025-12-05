class Club {
  final String id;
  final String name;
  final int unionNumber;

  Club({
    required this.id,
    required this.name,
    required this.unionNumber,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['ID'] ?? json['id'] ?? '',
      name: json['Name'] ?? json['name'] ?? '',
      unionNumber: json['UnionNumber'] ?? json['unionNumber'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Club && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}


