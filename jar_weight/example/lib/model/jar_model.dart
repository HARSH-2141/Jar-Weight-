import 'dart:convert';

class JarModel {
  String id;
  String name;
  double capacity;
  double currentWeight;
  String expiryDate;
  String addedDate;

  JarModel({
    required this.id,
    required this.name,
    required this.capacity,
    required this.currentWeight,
    required this.expiryDate,
    required this.addedDate,
  });

  double get percentage => currentWeight / capacity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'currentWeight': currentWeight,
      'expiryDate': expiryDate,
      'addedDate': addedDate,
    };
  }

  factory JarModel.fromMap(Map<String, dynamic> map) {
    return JarModel(
      id: map['id'],
      name: map['name'],
      capacity: map['capacity'],
      currentWeight: map['currentWeight'],
      expiryDate: map['expiryDate'],
      addedDate: map['addedDate'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory JarModel.fromJson(String source) =>
      JarModel.fromMap(jsonDecode(source));
}
