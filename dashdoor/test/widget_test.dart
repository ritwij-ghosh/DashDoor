import 'package:dashdoor/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Theme builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ProviderContainer().read(appThemeProvider),
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
