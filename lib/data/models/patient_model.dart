import 'package:hive/hive.dart';

part 'patient_model.g.dart';

@HiveType(typeId: 0)
class Patient extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  Patient({required this.name, required this.age});
}
