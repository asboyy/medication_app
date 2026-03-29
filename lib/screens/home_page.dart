import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/models/patient.dart';
import '../services/database_service.dart';
import 'history_page.dart';
import 'medication_list_page.dart';
import 'patient_form_page.dart';
import 'today_schedule_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication App'),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<Patient>>(
          valueListenable: DatabaseService.patientsBox.listenable(),
          builder: (context, box, _) {
            final patients = DatabaseService.getPatients();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _DashboardActions(patientsCount: patients.length),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Daftar pasien',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Kelola pasien dan masuk ke daftar obat masing-masing pasien.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: patients.isEmpty
                      ? const _EmptyPatientsState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: patients.length,
                          itemBuilder: (context, index) {
                            final patient = patients[index];
                            final medicationCount =
                                DatabaseService.getMedicationsForPatient(patient.id).length;

                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primaryContainer,
                                  child: const Icon(Icons.person_outline),
                                ),
                                title: Text(patient.name),
                                subtitle: Text(
                                  'Usia ${patient.age} tahun • $medicationCount obat',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PatientFormPage(patient: patient),
                                        ),
                                      );
                                    }

                                    if (value == 'delete') {
                                      final confirmed = await _showDeleteDialog(
                                        context,
                                        title: 'Hapus pasien?',
                                        message:
                                            'Semua obat dan riwayat milik ${patient.name} juga akan dihapus.',
                                      );
                                      if (confirmed == true) {
                                        await DatabaseService.deletePatient(patient.id);
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MedicationListPage(patient: patient),
                                    ),
                                  );
                                },
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
            MaterialPageRoute(builder: (_) => const PatientFormPage()),
          );
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah Pasien'),
      ),
    );
  }

  Future<bool?> _showDeleteDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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
        );
      },
    );
  }
}

class _DashboardActions extends StatelessWidget {
  const _DashboardActions({required this.patientsCount});

  final int patientsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan hari ini',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Pantau jadwal harian, riwayat konsumsi, dan data pasien dari satu dashboard.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Chip(
                  avatar: const Icon(Icons.groups_2_outlined, size: 18),
                  label: Text('$patientsCount pasien'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.today_outlined),
                  label: const Text('Jadwal Hari Ini'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TodaySchedulePage()),
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.history_outlined),
                  label: const Text('Riwayat & Kalender'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPatientsState extends StatelessWidget {
  const _EmptyPatientsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada pasien',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan pasien pertama untuk mulai mengelola obat, jadwal, dan riwayat konsumsi.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
