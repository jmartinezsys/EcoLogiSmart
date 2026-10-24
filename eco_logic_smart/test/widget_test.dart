import 'package:flutter_test/flutter_test.dart';

import 'package:eco_logic_smart/app.dart';

void main() {
  testWidgets('login opens the main dashboard and module navigation works', (
    tester,
  ) async {
    await tester.pumpWidget(const EcoLogiSmartApp());

    expect(find.text('EcoLogiSmart'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);

    await tester.tap(find.text('Explorar demostración'));
    await tester.pumpAndSettle();

    expect(find.text('¡Buenos días, Andrea!'), findsOneWidget);
    expect(find.text('Tu operación hoy'), findsOneWidget);

    await tester.tap(find.text('Recursos'));
    await tester.pumpAndSettle();
    expect(find.text('Recursos e inventario'), findsOneWidget);
  });

  testWidgets('login validates required credentials', (tester) async {
    await tester.pumpWidget(const EcoLogiSmartApp());
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe un correo válido'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
  });
}
