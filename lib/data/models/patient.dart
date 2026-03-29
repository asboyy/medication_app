import 'package:hive/hive.dart';

part 'patient.g.dart';

class PatientFields {
  static const int name = 0;
  static const int age = 1;
  static const int id = 2;
}

@HiveType(typeId: 0)
class Patient extends HiveObject {
  Patient({
    required this.id,
    required this.name,
    required this.age,
  });

  @HiveField(PatientFields.id)
  final int id;

  @HiveField(PatientFields.name)
  final String name;

  @HiveField(PatientFields.age)
  final int age;

  Patient copyWith({
    int? id,
    String? name,
    int? age,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }
}

class PatientAdapter extends TypeAdapter<Patient> {
  @override
  final int typeId = 0;

  @override
  Patient read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < fieldCount; index++) reader.readByte(): reader.read(),
    };

    final name = (fields[PatientFields.name] ?? '') as String;
    final age = (fields[PatientFields.age] ?? 0) as int;
    final fallbackId = Object.hash(name, age);

    return Patient(
      id: (fields[PatientFields.id] ?? fallbackId) as int,
      name: name,
      age: age,
    );
  }

  @override
  void write(BinaryWriter writer, Patient obj) {
    writer
      ..writeByte(3)
      ..writeByte(PatientFields.name)
      ..write(obj.name)
      ..writeByte(PatientFields.age)
      ..write(obj.age)
      ..writeByte(PatientFields.id)
      ..write(obj.id);
  }
}
