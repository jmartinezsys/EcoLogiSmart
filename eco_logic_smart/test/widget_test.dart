import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eco_logic_smart/app.dart';
import 'package:eco_logic_smart/app_shell.dart';
import 'package:eco_logic_smart/models/company_account.dart';
import 'package:eco_logic_smart/models/operational_records.dart';
import 'package:eco_logic_smart/services/local_account_store.dart';
import 'package:eco_logic_smart/services/workspace_repository.dart';

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

  testWidgets('inventory is added and restored after reopening the app', (
    tester,
  ) async {
    const account = CompanyAccount(
      businessName: 'Café La Plaza',
      contactName: 'Sara López',
      email: 'sara@laplaza.co',
      sector: 'Restaurante',
      city: 'Cartagena',
    );
    await tester.pumpWidget(MaterialApp(home: AppShell(account: account)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recursos').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Agregar recurso'));
    await tester.pumpAndSettle();

    Future<void> enterField(String label, String value) async {
      final field = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == label,
      );
      await tester.enterText(field, value);
    }

    await enterField('Nombre del recurso', 'Cajas reutilizables');
    await enterField('Cantidad disponible', '15');
    await enterField('Unidad', 'unidades');
    await enterField('Categoría', 'Empaque');
    await enterField('Nivel mínimo para alerta', '3');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Cajas reutilizables'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(home: AppShell(account: account)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recursos').last);
    await tester.pumpAndSettle();
    expect(find.text('Cajas reutilizables'), findsOneWidget);
    expect(find.text('15.0 unidades'), findsOneWidget);
  });

  test(
    'operational records persist and inventory stays scoped by company',
    () async {
      const company = CompanyAccount(
        businessName: 'Taller Verde',
        contactName: 'Ana Ruiz',
        email: 'ana@tallerverde.co',
        sector: 'Servicios',
        city: 'Cartagena',
      );
      const otherCompany = CompanyAccount(
        businessName: 'Hotel Bahía',
        contactName: 'Luis Díaz',
        email: 'luis@hotelbahia.co',
        sector: 'Turismo y hotelería',
        city: 'Cartagena',
      );

      await WorkspaceRepository.saveInventory(
        company,
        const InventoryItem(
          id: '',
          name: 'Cartón',
          quantity: 12,
          unit: 'kg',
          category: 'Embalaje',
          lowStockThreshold: 4,
        ),
      );
      await WorkspaceRepository.publishMaterial(
        account: company,
        listing: const MaterialListing(
          id: '',
          companyId: '',
          title: 'Retazos de tela',
          description: 'Limpios y clasificados',
          quantity: 8,
          unit: 'kg',
          status: 'Disponible',
          companyName: 'Taller Verde',
          city: 'Cartagena',
        ),
      );
      await WorkspaceRepository.requestRoute(
        account: company,
        destination: 'Manga',
        deliveryType: 'Materiales',
      );

      final inventory = await WorkspaceRepository.loadInventory(company);
      final materials = await WorkspaceRepository.loadMaterials();
      final routes = await WorkspaceRepository.loadRoutes();

      expect(inventory, hasLength(1));
      expect(inventory.single.quantity, 12);
      expect(await WorkspaceRepository.loadInventory(otherCompany), isEmpty);
      expect(materials.single.title, 'Retazos de tela');
      expect(routes.single.destination, 'Manga');
    },
  );
}
