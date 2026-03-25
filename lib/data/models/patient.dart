import 'package:hive/hive.dart';

part 'patient.g.dart'; // WAJIB, jangan dihapus

// ==========================
// MODEL PATIENT
// ==========================
@HiveType(typeId: 0)
class Patient extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  // Constructor
  Patient({required this.name, required this.age});
  @override
  String toString() {
    return 'Patient(name: $name, age: $age)';
  }
}
