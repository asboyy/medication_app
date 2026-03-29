import 'package:flutter/material.dart';

import '../data/models/medication.dart';
import '../data/models/patient.dart';
import '../services/database_service.dart';

class MedicationFormPage extends StatefulWidget {
  const MedicationFormPage({
    super.key,
    required this.patient,
    this.medication,
  });

  final Patient patient;
  final Medication? medication;

  @override
  State<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final List<TimeOfDay> _selectedTimes = <TimeOfDay>[];
  DateTimeRange? _dateRange;
  bool _isSaving = false;

  bool get _isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medication?.name ?? '');

    if (widget.medication != null) {
      _selectedTimes.addAll(
        widget.medication!.times.map(_timeFromStorage),
      );
      _dateRange = DateTimeRange(
        start: widget.medication!.startDate,
        end: widget.medication!.endDate,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) {
      return;
    }

    final exists = _selectedTimes.any(
      (time) => time.hour == pickedTime.hour && time.minute == pickedTime.minute,
    );

    if (exists) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jam tersebut sudah ada di daftar.')),
      );
      return;
    }

    setState(() {
      _selectedTimes
        ..add(pickedTime)
        ..sort(_compareTime);
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDateRange:
          _dateRange ?? DateTimeRange(start: now, end: now.add(const Duration(days: 7))),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _dateRange = DateTimeRange(
        start: DatabaseService.dateOnly(picked.start),
        end: DatabaseService.dateOnly(picked.end),
      );
    });
  }

  Future<void> _save() async {
    final validForm = _formKey.currentState?.validate() ?? false;
    if (!validForm || _selectedTimes.isEmpty || _dateRange == null || _isSaving) {
      if (_selectedTimes.isEmpty || _dateRange == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih minimal satu jam dan rentang tanggal.')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      await DatabaseService.saveMedication(
        patientId: widget.patient.id,
        name: _nameController.text.trim(),
        times: _selectedTimes.map(_formatTimeStorage).toList(),
        startDate: _dateRange!.start,
        endDate: _dateRange!.end,
        existing: widget.medication,
      );

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Jadwal obat diperbarui.' : 'Obat berhasil ditambahkan.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan obat: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Obat' : 'Tambah Obat'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pasien: ${widget.patient.name}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama obat',
                            prefixIcon: Icon(Icons.medication_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama obat wajib diisi.';
                            }
                            if (value.trim().length < 2) {
                              return 'Nama obat minimal 2 karakter.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Jam minum',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final time in _selectedTimes)
                              InputChip(
                                label: Text(time.format(context)),
                                onDeleted: () {
                                  setState(() => _selectedTimes.remove(time));
                                },
                              ),
                            ActionChip(
                              avatar: const Icon(Icons.access_time),
                              label: const Text('Tambah Jam'),
                              onPressed: _pickTime,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Periode obat',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _pickDateRange,
                          icon: const Icon(Icons.date_range_outlined),
                          label: Text(
                            _dateRange == null
                                ? 'Pilih tanggal mulai dan selesai'
                                : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Jadwal Obat'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static int _compareTime(TimeOfDay a, TimeOfDay b) {
    final aTotal = a.hour * 60 + a.minute;
    final bTotal = b.hour * 60 + b.minute;
    return aTotal.compareTo(bTotal);
  }

  static TimeOfDay _timeFromStorage(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatTimeStorage(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
