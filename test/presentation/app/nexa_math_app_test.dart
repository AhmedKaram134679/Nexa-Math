import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_math/presentation/presentation.dart';

void main() {
  group('NexaMathApp Presentation Foundation', () {
    testWidgets('renders NexaMath root shell without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const NexaMathApp());
      await tester.pumpAndSettle();

      expect(find.text('NexaMath'), findsOneWidget);
    });
  });
}
