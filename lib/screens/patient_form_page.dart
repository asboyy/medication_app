import 'package:flutter/material.dart';

import '../data/models/patient.dart';
import '../services/database_service.dart';

class PatientFormPage extends StatefulWidget {
  const PatientFormPage({super.key, this.patient});

  final Patient? patient;

  @override
  State<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends State<PatientFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  bool _isSaving = false;

  bool get _isEditing => widget.patient != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient?.name ?? '');
    _ageController = TextEditingController(
      text: widget.patient?.age.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await DatabaseService.savePatient(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        existing: widget.patient,
      );

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Data pasien diperbarui.' : 'Pasien berhasil ditambahkan.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pasien: $error')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Pasien' : 'Tambah Pasien'),
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
                          'Informasi pasien',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nama pasien',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama pasien wajib diisi.';
                            }
                            if (value.trim().length < 3) {
                              return 'Nama pasien minimal 3 karakter.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Usia',
                            prefixIcon: Icon(Icons.cake_outlined),
                            suffixText: 'tahun',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Usia wajib diisi.';
                            }
                            final age = int.tryParse(value.trim());
                            if (age == null) {
                              return 'Usia harus berupa angka.';
                            }
                            if (age <= 0 || age > 120) {
                              return 'Masukkan usia yang valid.';
                            }
                            return null;
                          },
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
                    label: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Pasien'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
