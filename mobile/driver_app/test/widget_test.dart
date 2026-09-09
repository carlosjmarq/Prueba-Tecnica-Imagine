import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driver_app/app.dart';

void main() {
  testWidgets('renders driver app placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DriverApp()));
    expect(find.text('Imagine Driver'), findsOneWidget);
  });
}