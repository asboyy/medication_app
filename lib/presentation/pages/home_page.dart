import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medication App")),
      body: Center(child: Text("Daftar Pasien")),
    );
  }
}
