import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sigma/core/services/auth_service.dart';
import 'package:sigma/presentation/providers/auth_provider.dart';
import 'package:sigma/presentation/screens/auth/login_screen.dart';

void main() {
  testWidgets('Smoke test renders LoginScreen', (WidgetTester tester) async {
    final authService = AuthService();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authService,
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('سيجما'), findsOneWidget);
    expect(find.text('نظام مالي متكامل وفق معايير القيد المزدوج'), findsOneWidget);
    expect(find.text('powered by pom-agency.online'), findsOneWidget);
    expect(find.text('تسجيل الدخول للنظام'), findsOneWidget);
  });
}
