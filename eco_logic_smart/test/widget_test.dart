import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eco_logic_smart/app.dart';
import 'package:eco_logic_smart/models/company_account.dart';
import 'package:eco_logic_smart/services/local_account_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('splash uses the isotipo and continues to login', (tester) async {
    await tester.pumpWidget(const EcoLogiSmartApp());
    expect(find.byType(Image), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear cuenta de empresa'), findsOneWidget);
  });

  testWidgets('a company signs into its own profile, not sample data', (
    tester,
  ) async {
    const account = CompanyAccount(
      businessName: 'Panadería La Ceiba',
      contactName: 'Luisa Pérez',
      email: 'luisa@laceiba.co',
      sector: 'Comercio',
      city: 'Cartagena',
    );
    await LocalAccountStore.register(
      account: account,
      password: 'clave-segura',
    );

    await tester.pumpWidget(const EcoLogiSmartApp());
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), account.email);
    await tester.enterText(find.byType(TextFormField).at(1), 'clave-segura');

    final signIn = find.text('Iniciar sesión');
    await tester.ensureVisible(signIn);
    await tester.pumpAndSettle();
    await tester.tap(signIn);
    await tester.pumpAndSettle();

    expect(find.text('Hola, Luisa'), findsOneWidget);
    expect(find.text('Panadería La Ceiba'), findsWidgets);
    expect(find.text('Comercio'), findsOneWidget);
    expect(find.text('Hola, Andrea'), findsNothing);
  });

  testWidgets('registration entry opens the company form', (tester) async {
    await tester.pumpWidget(const EcoLogiSmartApp());
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    final createAccount = find.text('Crear cuenta de empresa');
    await tester.ensureVisible(createAccount);
    await tester.pumpAndSettle();
    await tester.tap(createAccount);
    await tester.pumpAndSettle();

    expect(find.text('Registra tu negocio'), findsOneWidget);
    expect(find.text('Nombre de la empresa'), findsOneWidget);
  });
}
