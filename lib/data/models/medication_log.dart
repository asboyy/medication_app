import 'package:hive/hive.dart';

part 'medication_log.g.dart';

class MedicationLogFields {
  static const int id = 0;
  static const int medicationId = 1;
  static const int date = 2;
  static const int time = 3;
  static const int status = 4;
}

class MedicationLogStatus {
  static const String taken = 'taken';
  static const String missed = 'missed';
  static const String pending = 'pending';
}

@HiveType(typeId: 2)
class MedicationLog extends HiveObject {
  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.date,
    required this.time,
    required this.status,
  });

  @HiveField(MedicationLogFields.id)
  final int id;

  @HiveField(MedicationLogFields.medicationId)
  final int medicationId;

  @HiveField(MedicationLogFields.date)
  final DateTime date;

  @HiveField(MedicationLogFields.time)
  final String time;

  @HiveField(MedicationLogFields.status)
  final String status;

  MedicationLog copyWith({
    int? id,
    int? medicationId,
    DateTime? date,
    String? time,
    String? status,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }
}

class MedicationLogAdapter extends TypeAdapter<MedicationLog> {
  @override
  final int typeId = 2;

  @override
  MedicationLog read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var index = 0; index < fieldCount; index++) reader.readByte(): reader.read(),
    };

    return MedicationLog(
      id: fields[MedicationLogFields.id] as int,
      medicationId: fields[MedicationLogFields.medicationId] as int,
      date: fields[MedicationLogFields.date] as DateTime,
      time: fields[MedicationLogFields.time] as String,
      status: fields[MedicationLogFields.status] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MedicationLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(MedicationLogFields.id)
      ..write(obj.id)
      ..writeByte(MedicationLogFields.medicationId)
      ..write(obj.medicationId)
      ..writeByte(MedicationLogFields.date)
      ..write(obj.date)
      ..writeByte(MedicationLogFields.time)
      ..write(obj.time)
      ..writeByte(MedicationLogFields.status)
      ..write(obj.status);
  }
}
