import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:abadgar/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Abadgar Core Flow Test', () {
    testWidgets('Create a season and log an expense', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ensure we are on Dashboard
      expect(find.text('Dashboard'), findsWidgets);

      // 1. Navigate to Seasons Tab
      await tester.tap(find.byIcon(Icons.eco_rounded));
      await tester.pumpAndSettle();

      // 2. Click Add Season
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();

      // 3. Fill Season Name (Crop + Year)
      await tester.enterText(find.byType(TextField).first, 'Rice 2026');
      await tester.enterText(find.byType(TextField).at(1), '10'); // Area
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // 4. Record a Transaction via FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 5. Input Amount for Seed
      await tester.enterText(find.byType(TextField).first, '12000');
      // Select Category "Seed" (Localizing 'Seed' foundation)
      await tester.tap(find.text('Seed'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // 6. Verify Dashboard Metrics show 12,000
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('12,000'), findsWidgets); 
    });

    group('Analytics Verification', () {
      testWidgets('Check if metrics adjust after multiple logs', (tester) async {
        // Future analytics tests
      });
    });
  });
}
