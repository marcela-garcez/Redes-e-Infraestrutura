import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobileprimeiro/main.dart';
import 'package:mobileprimeiro/screens/login_screen.dart';

void main() {
  testWidgets('displays the splash screen at startup', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('opens the home screen after a valid login', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'usuario@email.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();

    expect(find.text('Produtos e serviços'), findsOneWidget);
  });
}
