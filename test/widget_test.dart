import 'package:flutter_test/flutter_test.dart';
import 'package:clipboard_typer/main.dart';

void main() {
  testWidgets('Settings page shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const ClipboardTyperApp());
    await tester.pumpAndSettle();
    expect(find.text('ClipboardTyper'), findsOneWidget);
  });
}
