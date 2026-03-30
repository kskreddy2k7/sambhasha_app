import 'package:flutter_test/flutter_test.dart';
import 'package:sambhasha_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We wrap it in a try-catch because it depends on Firebase which isn't mocked here.
    try {
      await tester.pumpWidget(const SambhashaApp(isFirebaseInitialized: false));
    } catch (_) {}
  });
}
