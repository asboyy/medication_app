import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medication_app/screens/patient_form_page.dart';

void main() {
  testWidgets('patient form renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PatientFormPage(),
      ),
    );

    expect(find.text('Tambah Pasien'), findsOneWidget);
    expect(find.text('Informasi pasien'), findsOneWidget);
    expect(find.text('Simpan Pasien'), findsOneWidget);
  });
}
