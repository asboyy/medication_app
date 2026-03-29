import 'package:hive/hive.dart';

part 'history.g.dart';

@HiveType(typeId: 2)
class History extends HiveObject {
  @HiveField(0)
  String medicationName;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  bool taken;

  History({
    required this.medicationName,
    required this.date,
    required this.taken,
  });
}
