import 'package:flutter/material.dart';

import '../api/auth_repository.dart';
import '../navigation/app_page_route.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_shell.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.auth});

  final AuthRepository auth;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final started = DateTime.now();
    Widget next = LoginScreen(auth: widget.auth);

    try {
      if (await widget.auth.hasSession()) {
        await widget.auth.me();
        next = HomeScreen(auth: widget.auth);
      }
    } catch (_) {
      await widget.auth.clearSession();
      next = LoginScreen(auth: widget.auth);
    }

    final elapsed = DateTime.now().difference(started);
    final remaining = const Duration(milliseconds: 1600) - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) return;

    await AppPageRoute.pushReplacement(context, next);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BrandMark(size: 84),
                    const SizedBox(height: 28),
                    const Text(
                      'CarePath',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your clinic, appointments, and care\nin one calm place.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: AppColors.teal.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
