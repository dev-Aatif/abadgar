import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:abadgar/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Flow', () {
    testWidgets('Cold start renders onboarding and navigates to Seasons flow',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Abadgar!'), findsOneWidget);
      expect(find.text('Start New Season'), findsOneWidget);

      await tester.tap(find.text('Start New Season'));
      await tester.pumpAndSettle();

      expect(find.text('Harvest Cycles'), findsOneWidget);
    });
  });
}
