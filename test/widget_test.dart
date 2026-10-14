import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_portal/api/api_client.dart';
import 'package:patient_portal/api/auth_repository.dart';
import 'package:patient_portal/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('login screen offers the clinic sign-in and API settings', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(auth: AuthRepository(ApiClient())),
    ));
    await tester.pump();

    expect(find.text('Patient portal'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Clinic / API'), findsOneWidget);

    await tester.tap(find.text('Clinic / API'));
    await tester.pumpAndSettle();

    expect(find.text('Portal address'), findsOneWidget);
    expect(find.text('Clinic slug'), findsOneWidget);
  });
}
