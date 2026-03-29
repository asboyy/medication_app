import 'package:hive_flutter/hive_flutter.dart';

import '../data/models/medication.dart';
import '../data/models/medication_log.dart';
import '../data/models/patient.dart';
import 'notification_service.dart';

class DatabaseService {
  DatabaseService._();

  static const String patientsBoxName = 'patients';
  static const String medicationsBoxName = 'medications';
  static const String medicationLogsBoxName = 'medication_logs';

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PatientAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MedicationAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MedicationLogAdapter());
    }

    await Hive.openBox<Patient>(patientsBoxName);
    await Hive.openBox<Medication>(medicationsBoxName);
    await Hive.openBox<MedicationLog>(medicationLogsBoxName);
  }

  static Box<Patient> get patientsBox => Hive.box<Patient>(patientsBoxName);
  static Box<Medication> get medicationsBox => Hive.box<Medication>(medicationsBoxName);
  static Box<MedicationLog> get medicationLogsBox =>
      Hive.box<MedicationLog>(medicationLogsBoxName);

  static int _nextIdFromIterable(Iterable<int> ids) {
    const maxHiveIntKey = 0xFFFFFFFF;
    var nextId = 1;

    for (final id in ids) {
      if (id >= nextId && id < maxHiveIntKey) {
        nextId = id + 1;
      }
    }

    return nextId;
  }

  static int newPatientId() => _nextIdFromIterable(
    patientsBox.values.map((patient) => patient.id),
  );

  static int newMedicationId() => _nextIdFromIterable(
    medicationsBox.values.map((medication) => medication.id),
  );

  static int newMedicationLogId() => _nextIdFromIterable(
    medicationLogsBox.values.map((log) => log.id),
  );

  static Future<Patient> savePatient({
    required String name,
    required int age,
    Patient? existing,
  }) async {
    final patient = (existing ?? Patient(id: newPatientId(), name: name, age: age)).copyWith(
      name: name,
      age: age,
    );

    await patientsBox.put(patient.id, patient);
    return patient;
  }

  static Future<void> deletePatient(int patientId) async {
    final medications = getMedicationsForPatient(patientId);
    for (final medication in medications) {
      await deleteMedication(medication.id);
    }
    await patientsBox.delete(patientId);
  }

  static List<Patient> getPatients() {
    final patients = patientsBox.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return patients;
  }

  static Patient? getPatientById(int id) => patientsBox.get(id);

  static Future<Medication> saveMedication({
    required int patientId,
    required String name,
    required List<String> times,
    required DateTime startDate,
    required DateTime endDate,
    Medication? existing,
  }) async {
    final medication = (existing ??
            Medication(
              id: newMedicationId(),
              name: name,
              times: times,
              startDate: startDate,
              endDate: endDate,
              patientId: patientId,
            ))
        .copyWith(
          patientId: patientId,
          name: name,
          times: times,
          startDate: _dateOnly(startDate),
          endDate: _dateOnly(endDate),
        );

    await medicationsBox.put(medication.id, medication);
    await NotificationService.scheduleMedicationNotifications(medication);
    return medication;
  }

  static Future<void> deleteMedication(int medicationId) async {
    await NotificationService.cancelMedicationNotifications(medicationId);

    final relatedLogs = medicationLogsBox.values
        .where((log) => log.medicationId == medicationId)
        .map((log) => log.id)
        .toList();

    await medicationLogsBox.deleteAll(relatedLogs);
    await medicationsBox.delete(medicationId);
  }

  static Medication? getMedicationById(int id) => medicationsBox.get(id);

  static List<Medication> getMedicationsForPatient(int patientId) {
    final medications = medicationsBox.values
        .where((medication) => medication.patientId == patientId)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return medications;
  }

  static List<Medication> getAllMedications() {
    final medications = medicationsBox.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return medications;
  }

  static Future<void> syncLogsForDate(DateTime date) async {
    final targetDate = _dateOnly(date);
    final medications = getAllMedications().where(
      (medication) => isMedicationActiveOn(medication, targetDate),
    );

    for (final medication in medications) {
      for (final time in medication.times) {
        final existing = _findLog(medication.id, targetDate, time);
        final status = inferStatus(date: targetDate, time: time, currentTime: DateTime.now());

        if (existing == null) {
          final log = MedicationLog(
            id: newMedicationLogId(),
            medicationId: medication.id,
            date: targetDate,
            time: time,
            status: status,
          );
          await medicationLogsBox.put(log.id, log);
        } else if (existing.status != MedicationLogStatus.taken && existing.status != status) {
          await medicationLogsBox.put(existing.id, existing.copyWith(status: status));
        }
      }
    }
  }

  static Future<MedicationLog> markMedicationTaken({
    required int medicationId,
    required DateTime date,
    required String time,
  }) async {
    final targetDate = _dateOnly(date);
    final existing = _findLog(medicationId, targetDate, time);
    final log = (existing ??
            MedicationLog(
              id: newMedicationLogId(),
              medicationId: medicationId,
              date: targetDate,
              time: time,
              status: MedicationLogStatus.pending,
            ))
        .copyWith(status: MedicationLogStatus.taken);

    await medicationLogsBox.put(log.id, log);
    return log;
  }

  static List<MedicationLog> getLogsForDate(DateTime date) {
    final targetDate = _dateOnly(date);
    final logs = medicationLogsBox.values
        .where((log) => isSameDate(log.date, targetDate))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return logs;
  }

  static Map<DateTime, List<MedicationLog>> getLogsGroupedByDate() {
    final grouped = <DateTime, List<MedicationLog>>{};

    for (final log in medicationLogsBox.values) {
      final key = _dateOnly(log.date);
      grouped.putIfAbsent(key, () => <MedicationLog>[]).add(log);
    }

    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.time.compareTo(b.time));
    }

    return grouped;
  }

  static MedicationLog? getLogForMedicationTime({
    required int medicationId,
    required DateTime date,
    required String time,
  }) {
    return _findLog(medicationId, _dateOnly(date), time);
  }

  static bool isMedicationActiveOn(Medication medication, DateTime date) {
    final targetDate = _dateOnly(date);
    final start = _dateOnly(medication.startDate);
    final end = _dateOnly(medication.endDate);
    return !targetDate.isBefore(start) && !targetDate.isAfter(end);
  }

  static String inferStatus({
    required DateTime date,
    required String time,
    required DateTime currentTime,
  }) {
    final scheduled = combineDateAndTime(date, time);
    if (scheduled.isBefore(currentTime)) {
      return MedicationLogStatus.missed;
    }
    return MedicationLogStatus.pending;
  }

  static DateTime combineDateAndTime(DateTime date, String time) {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  static DateTime dateOnly(DateTime value) => _dateOnly(value);

  static bool isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static MedicationLog? _findLog(int medicationId, DateTime date, String time) {
    for (final log in medicationLogsBox.values) {
      if (log.medicationId == medicationId && isSameDate(log.date, date) && log.time == time) {
        return log;
      }
    }
    return null;
  }

  static DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);
}
