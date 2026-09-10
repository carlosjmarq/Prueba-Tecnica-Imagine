import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/app.dart';
import 'package:customer_app/features/orders/create_order_screen.dart';

void main() {
  testWidgets('renders login screen when not authenticated', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CustomerApp()));
    expect(find.text('Imagine Delivery'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('crear pedido permite adjuntar foto por item', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CreateOrderScreen()),
      ),
    );
    expect(find.text('Agregar foto'), findsNothing);

    await tester.tap(find.text('Agregar item'));
    await tester.pumpAndSettle();

    expect(find.text('Agregar foto'), findsOneWidget);
  });
}
