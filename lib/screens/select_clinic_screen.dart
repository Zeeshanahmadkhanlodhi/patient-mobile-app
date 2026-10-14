import 'package:flutter/material.dart';

import '../api/auth_repository.dart';
import '../navigation/app_page_route.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_shell.dart';
import 'home_screen.dart';

/// Post-registration (and later) picker for nearby clinics near the patient's address.
class SelectClinicScreen extends StatefulWidget {
  const SelectClinicScreen({
    super.key,
    required this.auth,
    this.fromRegistration = false,
  });

  final AuthRepository auth;
  final bool fromRegistration;

  @override
  State<SelectClinicScreen> createState() => _SelectClinicScreenState();
}

class _SelectClinicScreenState extends State<SelectClinicScreen> {
  List<Map<String, dynamic>> clinics = [];
  String? selectedId;
  String? error;
  bool loading = true;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await widget.auth.clinics();
      final rows = <Map<String, dynamic>>[
        for (final row in ((data['clinics'] as List<dynamic>?) ?? const []))
          if (row is Map) Map<String, dynamic>.from(row),
      ];
      final preferred = data['preferred_clinic'] as Map<String, dynamic>?;
      final nearest = data['nearest_clinic'] as Map<String, dynamic>?;

      setState(() {
        clinics = rows;
        selectedId = preferred?['id']?.toString() ??
            nearest?['id']?.toString() ??
            (rows.isNotEmpty ? rows.first['id']?.toString() : null);
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> _continue() async {
    final id = selectedId;
    if (id == null) {
      setState(() => error = 'Choose a clinic near you to continue.');
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    try {
      await widget.auth.setPreferredClinic(id);
      if (!mounted) return;
      if (widget.fromRegistration) {
        await AppPageRoute.pushReplacement(context, HomeScreen(auth: widget.auth));
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(widget.fromRegistration ? 24 : 8, 8, 16, 0),
            child: Row(
              children: [
                if (!widget.fromRegistration)
                  IconButton(
                    onPressed: busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                  ),
                const Expanded(
                  child: Text(
                    'Choose a clinic',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      const AuthHeader(
                        title: 'Clinics near you',
                        subtitle:
                            'Based on the address you entered, pick where you want to book visits. You can change this anytime and book at any nearby clinic.',
                      ),
                      const SizedBox(height: 24),
                      if (error != null) ...[
                        AuthErrorBanner(message: error!),
                        const SizedBox(height: 16),
                      ],
                      if (clinics.isEmpty)
                        const Text(
                          'No clinics were found for your address yet. Your clinic team can finish setup, or try again shortly.',
                          style: TextStyle(color: AppColors.muted, height: 1.45),
                        )
                      else
                        ...clinics.map(_clinicTile),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: AuthPrimaryButton(
              label: busy
                  ? 'Saving…'
                  : widget.fromRegistration
                      ? 'Continue to CarePath'
                      : 'Use this clinic',
              busy: busy,
              onPressed: clinics.isEmpty ? null : _continue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _clinicTile(Map<String, dynamic> clinic) {
    final id = clinic['id']?.toString() ?? '';
    final selected = id == selectedId;
    final isNearest = clinic['is_nearest'] == true;
    final reason = clinic['reason']?.toString();
    final address = clinic['address']?.toString();
    final phone = clinic['phone']?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? const Color(0xFFE7F0EF) : AppColors.fieldFill,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: busy ? null : () => setState(() => selectedId = id),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.teal : AppColors.line,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? AppColors.teal : AppColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              clinic['name']?.toString() ?? 'Clinic',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          if (isNearest)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Nearest',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tealSoft,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (address != null && address.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(address, style: const TextStyle(color: AppColors.muted, height: 1.35)),
                      ],
                      if (reason != null && reason.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(reason, style: const TextStyle(color: AppColors.tealSoft, fontSize: 13)),
                      ],
                      if (phone != null && phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(phone, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
