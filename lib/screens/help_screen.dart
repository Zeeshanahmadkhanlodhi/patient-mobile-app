import 'package:flutter/material.dart';

import '../api/auth_repository.dart';
import '../api/messages_repository.dart';
import '../navigation/app_page_route.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/feature_shell.dart';
import 'messages_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, required this.auth});

  final AuthRepository auth;

  static const _faqs = [
    (
      'How do I book a visit?',
      'Tap the center Book button, pick a clinic near you, choose a provider and time, then confirm. You can book at any clinic in the network, not only your preferred one.',
    ),
    (
      'How do I check in?',
      'On the day of your visit, open the appointment from Home and tap Check in. Check-in usually opens a few hours before your appointment.',
    ),
    (
      'Where are my lab results?',
      'Open the Records tab, then Results. Some results stay held until your clinic releases them.',
    ),
    (
      'How do I message the clinic?',
      'Use Inbox to message front desk, clinical, or billing. Replies stay in that conversation.',
    ),
    (
      'Who can see my chart?',
      'Privacy controls what the portal shows you (notes, results, billing). Your care team still uses the clinic EMR for treatment.',
    ),
    (
      'Is this an emergency line?',
      'No. For emergencies call 911 or go to the nearest ER. For urgent clinical questions, call your clinic’s main number.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FeatureShell(
      title: 'Help & support',
      subtitle: 'Guides and clinic contact',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          DashboardCard(
            color: AppColors.teal,
            borderColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need a human?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
                ),
                const SizedBox(height: 6),
                Text(
                  'Send a secure message to front desk, clinical, or billing. Your clinic replies in Inbox.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), height: 1.4),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => AppPageRoute.push(
                    context,
                    MessagesScreen(messages: MessagesRepository(auth.client)),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.tealDeep,
                  ),
                  child: const Text('Open Inbox'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel('Common questions'),
          const SizedBox(height: 8),
          ..._faqs.map(
            (faq) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DashboardCard(
                elevated: false,
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 4),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text(
                    faq.$1,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        faq.$2,
                        style: const TextStyle(color: AppColors.muted, height: 1.45, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          DashboardCard(
            elevated: false,
            color: AppColors.tealMist,
            child: const Text(
              'CarePath is your clinic’s patient portal. Account linking and chart updates are handled by your care team.',
              style: TextStyle(color: AppColors.tealDeep, height: 1.4, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
