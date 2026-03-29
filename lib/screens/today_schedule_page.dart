import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/models/medication.dart';
import '../data/models/medication_log.dart';
import '../data/models/patient.dart';
import '../services/database_service.dart';

class TodaySchedulePage extends StatefulWidget {
  const TodaySchedulePage({super.key, this.patientId});

  final int? patientId;

  @override
  State<TodaySchedulePage> createState() => _TodaySchedulePageState();
}

class _TodaySchedulePageState extends State<TodaySchedulePage> {
  final DateTime _today = DatabaseService.dateOnly(DateTime.now());
  bool _isSyncing = true;

  @override
  void initState() {
    super.initState();
    _syncToday();
  }

  Future<void> _syncToday() async {
    await DatabaseService.syncLogsForDate(_today);
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _markTaken(_ScheduleEntry entry) async {
    await DatabaseService.markMedicationTaken(
      medicationId: entry.medication.id,
      date: _today,
      time: entry.time,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.medication.name} ditandai sudah diminum.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientId == null ? 'Jadwal Hari Ini' : 'Checklist Minum Obat'),
      ),
      body: SafeArea(
        child: _isSyncing
            ? const Center(child: CircularProgressIndicator())
            : ValueListenableBuilder<Box<MedicationLog>>(
                valueListenable: DatabaseService.medicationLogsBox.listenable(),
                builder: (context, _, __) {
                  final schedule = _buildSchedule();
                  if (schedule.isEmpty) {
                    return const _EmptyTodayState();
                  }

                  final groups = <String, List<_ScheduleEntry>>{};
                  for (final entry in schedule) {
                    groups.putIfAbsent(entry.time, () => <_ScheduleEntry>[]).add(entry);
                  }
                  final times = groups.keys.toList()..sort();

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: times.length,
                    itemBuilder: (context, index) {
                      final time = times[index];
                      final entries = groups[time]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  time,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                for (final entry in entries)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ScheduleTile(
                                      entry: entry,
                                      onTaken: entry.status == MedicationLogStatus.taken
                                          ? null
                                          : () => _markTaken(entry),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  List<_ScheduleEntry> _buildSchedule() {
    final medications = DatabaseService.getAllMedications()
        .where((medication) => DatabaseService.isMedicationActiveOn(medication, _today))
        .where((medication) => widget.patientId == null || medication.patientId == widget.patientId)
        .toList();

    final entries = <_ScheduleEntry>[];
    for (final medication in medications) {
      final patient = DatabaseService.getPatientById(medication.patientId);
      if (patient == null) {
        continue;
      }
      for (final time in medication.times) {
        final log = DatabaseService.getLogForMedicationTime(
          medicationId: medication.id,
          date: _today,
          time: time,
        );
        entries.add(
          _ScheduleEntry(
            patient: patient,
            medication: medication,
            time: time,
            status: log?.status ?? MedicationLogStatus.pending,
          ),
        );
      }
    }

    entries.sort((a, b) {
      final timeCompare = a.time.compareTo(b.time);
      if (timeCompare != 0) {
        return timeCompare;
      }
      return a.medication.name.compareTo(b.medication.name);
    });
    return entries;
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.entry, required this.onTaken});

  final _ScheduleEntry entry;
  final VoidCallback? onTaken;

  @override
  Widget build(BuildContext context) {
    final iconData = switch (entry.status) {
      MedicationLogStatus.taken => Icons.check_circle,
      MedicationLogStatus.missed => Icons.cancel,
      _ => Icons.radio_button_unchecked,
    };
    final color = switch (entry.status) {
      MedicationLogStatus.taken => Colors.green,
      MedicationLogStatus.missed => Colors.red,
      _ => Colors.orange,
    };
    final statusLabel = switch (entry.status) {
      MedicationLogStatus.taken => 'Sudah diminum',
      MedicationLogStatus.missed => 'Terlewat',
      _ => 'Menunggu',
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(iconData, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.medication.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('Pasien: ${entry.patient.name}'),
                const SizedBox(height: 2),
                Text(statusLabel),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: onTaken,
            icon: const Icon(Icons.check),
            label: Text(
              entry.status == MedicationLogStatus.taken ? 'Sudah' : 'Sudah Minum',
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleEntry {
  const _ScheduleEntry({
    required this.patient,
    required this.medication,
    required this.time,
    required this.status,
  });

  final Patient patient;
  final Medication medication;
  final String time;
  final String status;
}

class _EmptyTodayState extends StatelessWidget {
  const _EmptyTodayState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada jadwal hari ini',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Saat obat aktif tersedia pada tanggal hari ini, jadwal akan otomatis muncul di sini.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
