import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/auth/presentation/screens/login_screen.dart';
import 'support/fakes.dart';

Widget _app(FakeAuthRepository repository) {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(repository),
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  testWidgets('validates required fields', (tester) async {
    await tester.pumpWidget(_app(FakeAuthRepository()));

    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();

    expect(find.text('Please enter email'), findsOneWidget);
    expect(find.text('Please enter password'), findsOneWidget);
  });

  testWidgets('shows the error message when login fails', (tester) async {
    final repository = FakeAuthRepository()..error = invalidCredentials;
    await tester.pumpWidget(_app(repository));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'a@b.c');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'bad');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Invalid email or password'), findsOneWidget);
  });
}
