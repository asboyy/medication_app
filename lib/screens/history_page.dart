import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../data/models/medication.dart';
import '../data/models/medication_log.dart';
import '../services/database_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime _focusedDay = DatabaseService.dateOnly(DateTime.now());
  DateTime _selectedDay = DatabaseService.dateOnly(DateTime.now());
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _syncSelectedDay();
  }

  Future<void> _syncSelectedDay() async {
    setState(() => _isLoading = true);
    await DatabaseService.syncLogsForDate(_selectedDay);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat & Kalender')),
      body: SafeArea(
        child: ValueListenableBuilder<Box<MedicationLog>>(
          valueListenable: DatabaseService.medicationLogsBox.listenable(),
          builder: (context, _, __) {
            final logs = DatabaseService.getLogsForDate(_selectedDay);
            final groupedLogs = DatabaseService.getLogsGroupedByDate();
            final takenCount = logs.where((log) => log.status == MedicationLogStatus.taken).length;
            final missedCount = logs.where((log) => log.status == MedicationLogStatus.missed).length;
            final pendingCount = logs.where((log) => log.status == MedicationLogStatus.pending).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TableCalendar<MedicationLog>(
                      firstDay: DateTime.now().subtract(const Duration(days: 365)),
                      lastDay: DateTime.now().add(const Duration(days: 365 * 3)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => DatabaseService.isSameDate(day, _selectedDay),
                      eventLoader: (day) =>
                          groupedLogs[DatabaseService.dateOnly(day)] ?? const <MedicationLog>[],
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      onDaySelected: (selectedDay, focusedDay) async {
                        setState(() {
                          _selectedDay = DatabaseService.dateOnly(selectedDay);
                          _focusedDay = DatabaseService.dateOnly(focusedDay);
                        });
                        await _syncSelectedDay();
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = DatabaseService.dateOnly(focusedDay);
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan ${_formatDate(_selectedDay)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              avatar: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                              label: Text('$takenCount diminum'),
                            ),
                            Chip(
                              avatar: const Icon(Icons.cancel, color: Colors.red, size: 18),
                              label: Text('$missedCount terlewat'),
                            ),
                            Chip(
                              avatar: const Icon(Icons.schedule, color: Colors.orange, size: 18),
                              label: Text('$pendingCount menunggu'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (logs.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Belum ada riwayat untuk tanggal ini.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...logs.map((log) {
                    final medication = DatabaseService.getMedicationById(log.medicationId);
                    final statusData = _statusData(log.status);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Icon(statusData.icon, color: statusData.color),
                          title: Text(medication?.name ?? 'Obat tidak ditemukan'),
                          subtitle: Text('${log.time} • ${statusData.label}'),
                          trailing: medication == null ? null : Text(_patientLabel(medication)),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  String _patientLabel(Medication medication) {
    return DatabaseService.getPatientById(medication.patientId)?.name ?? '-';
  }

  _StatusData _statusData(String status) {
    switch (status) {
      case MedicationLogStatus.taken:
        return const _StatusData('Sudah diminum', Icons.check_circle, Colors.green);
      case MedicationLogStatus.missed:
        return const _StatusData('Terlewat', Icons.cancel, Colors.red);
      default:
        return const _StatusData('Menunggu', Icons.schedule, Colors.orange);
    }
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _StatusData {
  const _StatusData(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
