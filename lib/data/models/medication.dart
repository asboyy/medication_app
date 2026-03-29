import 'package:hive/hive.dart';

part 'medication.g.dart';

class MedicationFields {
  static const int name = 0;
  static const int times = 1;
  static const int startDate = 2;
  static const int endDate = 3;
  static const int patientId = 4;
  static const int id = 5;
}

@HiveType(typeId: 1)
class Medication extends HiveObject {
  Medication({
    required this.id,
    required this.name,
    required this.times,
    required this.startDate,
    required this.endDate,
    required this.patientId,
  });

  @HiveField(MedicationFields.id)
  final int id;

  @HiveField(MedicationFields.name)
  final String name;

  @HiveField(MedicationFields.times)
  final List<String> times;

  @HiveField(MedicationFields.startDate)
  final DateTime startDate;

  @HiveField(MedicationFields.endDate)
  final DateTime endDate;

  @HiveField(MedicationFields.patientId)
  final int patientId;

  Medication copyWith({
    int? id,
    String? name,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    int? patientId,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      patientId: patientId ?? this.patientId,
    );
  }
}

class MedicationAdapter extends TypeAdapter<Medication> {
  @override
  final int typeId = 1;

  @override
  Medication read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < fieldCount; index++) reader.readByte(): reader.read(),
    };

    final name = (fields[MedicationFields.name] ?? '') as String;
    final times = ((fields[MedicationFields.times] ?? <String>[]) as List).cast<String>();
    final startDate = (fields[MedicationFields.startDate] ?? DateTime.now()) as DateTime;
    final endDate = (fields[MedicationFields.endDate] ?? DateTime.now()) as DateTime;
    final fallbackId = Object.hash(name, startDate.microsecondsSinceEpoch, endDate.microsecondsSinceEpoch);

    return Medication(
      id: (fields[MedicationFields.id] ?? fallbackId) as int,
      name: name,
      times: times,
      startDate: startDate,
      endDate: endDate,
      patientId: (fields[MedicationFields.patientId] ?? -1) as int,
    );
  }

  @override
  void write(BinaryWriter writer, Medication obj) {
    writer
      ..writeByte(6)
      ..writeByte(MedicationFields.name)
      ..write(obj.name)
      ..writeByte(MedicationFields.times)
      ..write(obj.times)
      ..writeByte(MedicationFields.startDate)
      ..write(obj.startDate)
      ..writeByte(MedicationFields.endDate)
      ..write(obj.endDate)
      ..writeByte(MedicationFields.patientId)
      ..write(obj.patientId)
      ..writeByte(MedicationFields.id)
      ..write(obj.id);
  }
}
