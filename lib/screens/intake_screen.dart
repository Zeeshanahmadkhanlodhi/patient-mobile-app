import 'package:flutter/material.dart';

import '../api/intake_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/feature_shell.dart';

const choices = ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'];

class IntakeScreen extends StatefulWidget {
  const IntakeScreen({super.key, required this.intake});

  final IntakeRepository intake;

  @override
  State<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends State<IntakeScreen> {
  List<String> questions = const [];
  List<int> answers = List<int>.filled(9, 0);
  Map<String, dynamic>? latest;
  bool nppAck = false;
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.intake.show();
      final items = ((data['questions'] as List<dynamic>?) ?? []).map((row) => row.toString()).toList();
      setState(() {
        questions = items;
        answers = List<int>.filled(items.length, 0);
        latest = data['latest'] as Map<String, dynamic>?;
        error = null;
      });
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> _submit() async {
    if (!nppAck) {
      setState(() => error = 'Acknowledge the privacy notice to send this intake.');
      return;
    }
    setState(() => busy = true);
    try {
      final saved = await widget.intake.submit(answers);
      setState(() {
        latest = saved;
        error = null;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureShell(
      title: 'Intake',
      subtitle: 'PHQ-9 before your visit',
      child: error != null && questions.isEmpty
          ? Center(child: Text(error!, style: const TextStyle(color: AppColors.danger)))
          : questions.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                  children: [
                    const DashboardCard(
                      elevated: false,
                      color: AppColors.tealMist,
                      child: Text(
                        'PHQ-9 before your visit. Scores go to the care team. This is not an emergency line — call 911 if you are in danger.',
                        style: TextStyle(color: AppColors.tealDeep, height: 1.4),
                      ),
                    ),
                    if (latest != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text('Last score ${latest!['score']} on ${latest!['completed_at']}.'),
                        ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(error!, style: const TextStyle(color: Colors.red)),
                        ),
                      ...List.generate(questions.length, (index) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(questions[index], style: const TextStyle(fontWeight: FontWeight.w600)),
                            ...List.generate(choices.length, (choice) {
                              return RadioListTile<int>(
                                contentPadding: EdgeInsets.zero,
                                title: Text(choices[choice]),
                                value: choice,
                                groupValue: answers[index],
                                onChanged: (value) => setState(() => answers[index] = value ?? 0),
                              );
                            }),
                          ],
                        );
                      }),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: nppAck,
                        onChanged: (value) => setState(() => nppAck = value ?? false),
                        title: const Text('I acknowledge the Notice of Privacy Practices and financial policy.'),
                      ),
                      FilledButton(onPressed: busy ? null : _submit, child: const Text('Send intake')),
                    ],
                  ),
    );
  }
}
