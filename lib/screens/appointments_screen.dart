import 'package:flutter/material.dart';

import '../api/appointments_repository.dart';
import '../api/auth_repository.dart';
import '../navigation/app_page_route.dart';
import '../theme/app_colors.dart';
import '../utils/app_haptics.dart';
import '../widgets/dashboard_widgets.dart';
import 'visit_detail_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({
    super.key,
    required this.appointments,
    required this.auth,
  });

  final AppointmentsRepository appointments;
  final AuthRepository auth;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<dynamic> upcoming = [];
  List<Map<String, dynamic>> clinics = [];
  List<dynamic> providers = [];
  List<dynamic> slots = [];
  String? facilityId;
  String? facilityName;
  String? providerId;
  String? error;
  bool busy = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final clinicData = await widget.auth.clinics();
      final rows = <Map<String, dynamic>>[
        for (final row in ((clinicData['clinics'] as List<dynamic>?) ?? const []))
          if (row is Map) Map<String, dynamic>.from(row),
      ];
      final preferred = clinicData['preferred_clinic'] as Map<String, dynamic>?;
      final nearest = clinicData['nearest_clinic'] as Map<String, dynamic>?;
      final chosenId = preferred?['id']?.toString() ??
          nearest?['id']?.toString() ??
          (rows.isNotEmpty ? rows.first['id']?.toString() : null);
      Map<String, dynamic>? chosen;
      for (final row in rows) {
        if (row['id']?.toString() == chosenId) {
          chosen = row;
          break;
        }
      }
      chosen ??= rows.isNotEmpty ? rows.first : null;

      setState(() {
        clinics = rows;
        facilityId = chosenId;
        facilityName = chosen?['name']?.toString() ?? preferred?['name']?.toString();
      });
      await _load();
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> _load() async {
    try {
      final visits = await widget.appointments.list();
      final docs = await widget.appointments.providers(facilityId: facilityId);
      setState(() {
        upcoming = visits;
        providers = docs;
        providerId = docs.isNotEmpty ? docs.first['id'] as String? : null;
        error = null;
        loading = false;
      });
      if (providerId != null) {
        await _loadSlots(providerId!);
      } else {
        setState(() => slots = []);
      }
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> _selectClinic(Map<String, dynamic> clinic) async {
    setState(() {
      facilityId = clinic['id']?.toString();
      facilityName = clinic['name']?.toString();
      busy = true;
    });
    try {
      await _load();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _loadSlots(String id) async {
    final open = await widget.appointments.slots(id, facilityId: facilityId);
    setState(() {
      providerId = id;
      slots = open;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : error != null && clinics.isEmpty
                ? Text(error!, style: const TextStyle(color: AppColors.danger))
                : ListView(
                    padding: const EdgeInsets.only(bottom: 110),
                    children: [
                      const Text(
                        'Book at a nearby clinic',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.ink),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pick any clinic near your address, then choose a doctor and time.',
                        style: TextStyle(color: AppColors.muted, height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      if (clinics.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: clinics.map((clinic) {
                            final id = clinic['id']?.toString() ?? '';
                            final selected = id == facilityId;
                            return ChoiceChip(
                              label: Text(
                                [
                                  clinic['name']?.toString() ?? 'Clinic',
                                  if (clinic['is_nearest'] == true) '· Nearest',
                                ].join(' '),
                              ),
                              selected: selected,
                              onSelected: busy ? null : (_) => _selectClinic(clinic),
                              selectedColor: const Color(0xFFE7F0EF),
                              labelStyle: TextStyle(
                                color: selected ? AppColors.teal : AppColors.ink,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(error!, style: const TextStyle(color: AppColors.danger)),
                      ],
                      const SizedBox(height: 20),
                      const Text('Upcoming', style: TextStyle(fontWeight: FontWeight.w600)),
                      if (upcoming.isEmpty) const Text('No booked visits.', style: TextStyle(color: AppColors.muted)),
                      ...upcoming.map((visit) {
                        final map = Map<String, dynamic>.from(visit as Map);
                        final checkedIn = map['checked_in'] == true;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          color: AppColors.fieldFill,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppColors.line),
                          ),
                          child: ListTile(
                            onTap: () async {
                              final changed = await AppPageRoute.push<bool>(
                                context,
                                VisitDetailScreen(appointments: widget.appointments, visit: map),
                              );
                              if (changed == true) await _load();
                            },
                            title: Text(map['provider_name']?.toString() ?? 'Visit'),
                            subtitle: Text([
                              if (map['facility_name'] != null) map['facility_name'],
                              formatVisitWhen(map['starts_at']?.toString()),
                              if (checkedIn) 'Checked in',
                            ].whereType<Object>().join(' · ')),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      const Text('Doctors', style: TextStyle(fontWeight: FontWeight.w600)),
                      if (providers.isEmpty)
                        const Text(
                          'No doctors available at this clinic right now.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      Wrap(
                        spacing: 8,
                        children: providers.map((provider) {
                          final map = provider as Map<String, dynamic>;
                          final id = map['id'] as String;
                          return ChoiceChip(
                            label: Text(map['name']?.toString() ?? id),
                            selected: id == providerId,
                            onSelected: busy ? null : (_) => _loadSlots(id),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Open times', style: TextStyle(fontWeight: FontWeight.w600)),
                      if (slots.isEmpty)
                        const Text(
                          'No open times for this doctor at the selected clinic.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ...slots.map((slot) {
                        final map = slot as Map<String, dynamic>;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(map['label']?.toString() ?? map['start'].toString()),
                          onTap: busy || providerId == null
                              ? null
                              : () async {
                                  await AppHaptics.action();
                                  setState(() => busy = true);
                                  try {
                                    await widget.appointments.book(
                                      providerId!,
                                      map['start'] as String,
                                      facilityId: facilityId,
                                      facilityName: facilityName,
                                    );
                                    await AppHaptics.success();
                                    await _load();
                                  } catch (e) {
                                    setState(() => error = e.toString().replaceFirst('Exception: ', ''));
                                  } finally {
                                    setState(() => busy = false);
                                  }
                                },
                        );
                      }),
                    ],
                  ),
      ),
    );
  }
}
