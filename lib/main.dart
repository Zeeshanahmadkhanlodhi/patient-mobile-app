import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/appointments_repository.dart';
import 'api/auth_repository.dart';
import 'api/billing_repository.dart';
import 'api/messages_repository.dart';
import 'deep_links/deep_link_service.dart';
import 'navigation/app_page_route.dart';
import 'push/push_service.dart';
import 'screens/appointments_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthRepository(ApiClient());
  await PushService.instance.initialize(
    onOpened: (data) => _openFromPush(auth, data),
  );
  await DeepLinkService.instance.start(
    auth: auth,
    navigatorKey: appNavigatorKey,
  );
  runApp(PatientPortalApp(auth: auth));
}

void _openFromPush(AuthRepository auth, Map<String, dynamic> data) {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return;

  final type = (data['type'] ?? data['category'] ?? '').toString();
  final isAppointment = type.startsWith('appointment') || type == 'appointments';
  final isPayment = type == 'payment_request' || type == 'payment_received' || type == 'payment_refunded' || type == 'billing';

  nav.push(
    AppPageRoute(
      builder: (_) => isPayment
          ? BillingScreen(billing: BillingRepository(auth.client))
          : isAppointment
          ? AppointmentsScreen(
              appointments: AppointmentsRepository(auth.client),
              auth: auth,
            )
          : MessagesScreen(messages: MessagesRepository(auth.client)),
    ),
  );
}

class PatientPortalApp extends StatelessWidget {
  const PatientPortalApp({super.key, required this.auth});

  final AuthRepository auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'CarePath',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          surface: AppColors.cream,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.cream,
        useMaterial3: true,
        splashFactory: InkSparkle.splashFactory,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.fieldFill,
          indicatorColor: AppColors.tealMist,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.tealDeep : AppColors.muted,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 20,
              color: selected ? AppColors.teal : AppColors.muted,
            );
          }),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: SplashScreen(auth: auth),
    );
  }
}
