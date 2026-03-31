import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/medication.dart';
import '../../data/models/patient.dart';
import '../../services/database_service.dart';
import '../../screens/history_page.dart';
import '../../screens/medication_list_page.dart';
import '../../screens/patient_form_page.dart';
import '../../screens/today_schedule_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Patient>>(
      valueListenable: DatabaseService.patientsBox.listenable(),
      builder: (context, _, __) {
        return ValueListenableBuilder<Box<Medication>>(
          valueListenable: DatabaseService.medicationsBox.listenable(),
          builder: (context, _, __) {
            final patients = DatabaseService.getPatients();
            final medications = DatabaseService.getAllMedications();
            final today = DatabaseService.dateOnly(DateTime.now());
            final activeToday = medications
                .where((medication) => DatabaseService.isMedicationActiveOn(medication, today))
                .length;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Medication App'),
                actions: [
                  IconButton(
                    tooltip: 'Riwayat',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryPage()),
                      );
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                  ),
                ],
              ),
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pantau jadwal minum obat dengan lebih rapi.',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kelola pasien, cek obat aktif hari ini, dan buka riwayat dari satu halaman.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.92),
                                ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _QuickActionButton(
                                icon: Icons.today_outlined,
                                label: 'Jadwal Hari Ini',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TodaySchedulePage(),
                                    ),
                                  );
                                },
                              ),
                              _QuickActionButton(
                                icon: Icons.person_add_alt_1_outlined,
                                label: 'Tambah Pasien',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PatientFormPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Pasien',
                            value: '${patients.length}',
                            icon: Icons.people_alt_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            title: 'Obat Aktif',
                            value: '$activeToday',
                            icon: Icons.medication_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daftar Pasien',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HistoryPage()),
                            );
                          },
                          child: const Text('Lihat Riwayat'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (patients.isEmpty)
                      const _EmptyPatientsState()
                    else
                      ...patients.map(
                        (patient) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PatientCard(patient: patient),
                        ),
                      ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PatientFormPage()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Tambah Pasien'),
              ),
            );
          },
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.18),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final medications = DatabaseService.getMedicationsForPatient(patient.id);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          child: Text(
            patient.name.isEmpty ? '?' : patient.name[0].toUpperCase(),
          ),
        ),
        title: Text(patient.name),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Usia ${patient.age} tahun - ${medications.length} obat terdaftar',
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
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
  }
}

class _EmptyPatientsState extends StatelessWidget {
  const _EmptyPatientsState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Belum ada pasien',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan data pasien lebih dulu agar jadwal obat dan checklist harian bisa digunakan.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientFormPage()),
                );
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Tambah Pasien'),
            ),
          ],
        ),
      ),
    );
  }
}
