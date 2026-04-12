import 'package:agrisupply/providers/auth_provider.dart';
import 'package:agrisupply/screens/auth/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class StubAuthProvider extends ChangeNotifier implements AuthProvider {
  int sendOtpCalls = 0;
  String? lastPhone;

  @override
  Future<String?> sendPasswordResetOtp({required String phone}) async {
    sendOtpCalls += 1;
    lastPhone = phone;
    return '123456';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('Forgot password screen sends OTP and moves to verify step', (tester) async {
    final authProvider = StubAuthProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const MaterialApp(home: ForgotPasswordScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, '0772123456');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(authProvider.sendOtpCalls, 1);
    expect(authProvider.lastPhone, '0772123456');
    expect(find.text('Verify OTP'), findsOneWidget);
    expect(find.textContaining('Dev OTP:'), findsOneWidget);
  });
}
