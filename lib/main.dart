import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/patient.dart';

// 🔔 Service notifikasi
import 'services/notification_service.dart';

void main() async {
  // Wajib untuk async di main
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================
  // 🗄️ INIT HIVE
  // ==========================
  await Hive.initFlutter();

  // Register adapter (hindari double register saat hot reload)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PatientAdapter());
  }

  // Buka box (database lokal)
  await Hive.openBox<Patient>('patients');

  // ==========================
  // 🔔 INIT NOTIFIKASI
  // ==========================
  await NotificationService.init();

  // Jalankan aplikasi
  runApp(const MyApp());
}

// ==========================
// ROOT APP
// ==========================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medication App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

// ==========================
// HALAMAN UTAMA
// ==========================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil box sekali saja (lebih efisien)
    final box = Hive.box<Patient>('patients');

    return Scaffold(
      appBar: AppBar(title: const Text("Medication App"), centerTitle: true),

      // ==========================
      // BODY UI (LIST DATA)
      // ==========================
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),

        builder: (context, Box<Patient> box, _) {
          // Kalau belum ada data
          if (box.isEmpty) {
            return const Center(child: Text("Belum ada data pasien"));
          }

          // Kalau ada data → tampilkan list
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final patient = box.getAt(index);

              // Safety check (hindari crash)
              if (patient == null) return const SizedBox();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  // 👤 Nama pasien
                  title: Text(
                    patient.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  // 🎂 Umur pasien
                  subtitle: Text("Umur: ${patient.age} tahun"),

                  // 🗑️ Tombol hapus
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      box.deleteAt(index);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),

      // ==========================
      // ➕ BUTTON TAMBAH DATA + NOTIF
      // ==========================
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final box = Hive.box<Patient>('patients');

          // ➕ TAMBAH DATA (sementara masih hardcode)
          await box.add(Patient(name: "Fahmi", age: 25));

          // 🔍 Debug (lihat isi data)
          for (var p in box.values) {
            print(p);
          }

          // 🔔 NOTIFIKASI
          await NotificationService.showNotification(
            "Data ditambahkan",
            "Pasien berhasil disimpan",
          );
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}
