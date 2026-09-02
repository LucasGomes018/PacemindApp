// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pacemind/main.dart';

void main() {
  testWidgets('exibe a tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pumpAndSettle();
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.byIcon(Icons.email_rounded), findsOneWidget);
  });
}
