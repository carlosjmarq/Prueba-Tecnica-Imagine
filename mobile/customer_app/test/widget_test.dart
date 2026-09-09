import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/app.dart';

void main() {
  testWidgets('renders login screen when not authenticated', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CustomerApp()));
    expect(find.text('Imagine Delivery'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
