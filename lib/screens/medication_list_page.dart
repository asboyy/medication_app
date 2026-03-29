import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/models/medication.dart';
import '../data/models/patient.dart';
import '../services/database_service.dart';
import 'medication_form_page.dart';
import 'today_schedule_page.dart';

class MedicationListPage extends StatelessWidget {
  const MedicationListPage({super.key, required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patient.name),
        actions: [
          IconButton(
            tooltip: 'Checklist hari ini',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TodaySchedulePage(patientId: patient.id),
                ),
              );
            },
            icon: const Icon(Icons.checklist_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<Medication>>(
          valueListenable: DatabaseService.medicationsBox.listenable(),
          builder: (context, _, __) {
            final medications = DatabaseService.getMedicationsForPatient(patient.id);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text('Usia ${patient.age} tahun'),
                          const SizedBox(height: 12),
                          Chip(
                            avatar: const Icon(Icons.medication_outlined, size: 18),
                            label: Text('${medications.length} obat terdaftar'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TodaySchedulePage(patientId: patient.id),
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Checklist Obat Hari Ini'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: medications.isEmpty
                      ? const _EmptyMedicationState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: medications.length,
                          itemBuilder: (context, index) {
                            final medication = medications[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.secondaryContainer,
                                  child: const Icon(Icons.vaccines_outlined),
                                ),
                                title: Text(medication.name),
                                subtitle: Text(
                                  '${medication.times.join(', ')}\n${_formatDate(medication.startDate)} - ${_formatDate(medication.endDate)}',
                                ),
                                isThreeLine: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MedicationFormPage(
                                        patient: patient,
                                        medication: medication,
                                      ),
                                    ),
                                  );
                                },
                                trailing: IconButton(
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Hapus obat?'),
                                        content: Text(
                                          'Jadwal notifikasi dan riwayat untuk ${medication.name} akan ikut dihapus.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Batal'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      await DatabaseService.deleteMedication(medication.id);
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicationFormPage(patient: patient),
            ),
          );
        },
        icon: const Icon(Icons.add_alarm_outlined),
        label: const Text('Tambah Obat'),
      ),
    );
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

class _EmptyMedicationState extends StatelessWidget {
  const _EmptyMedicationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_liquid_outlined,
              size: 68,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada obat',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan jadwal obat untuk pasien ini agar pengingat dan riwayat bisa mulai berjalan.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
