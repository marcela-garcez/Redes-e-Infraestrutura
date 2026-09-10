import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileprimeiro/main.dart';
import 'package:mobileprimeiro/screens/login_screen.dart';

void main() {
  testWidgets('exibe a splash screen ao iniciar', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('valida campos obrigatórios antes de chamar o Firebase', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(find.text('ENTRAR'));
    await tester.pump();

    expect(find.text('Informe seu e-mail'), findsOneWidget);
    expect(find.text('Informe sua senha'), findsOneWidget);
  });
}
