import 'package:flutter/material.dart';

import '../api/messages_repository.dart';
import '../navigation/app_page_route.dart';
import '../theme/app_colors.dart';
import '../utils/app_haptics.dart';
import '../widgets/dashboard_widgets.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.messages});

  final MessagesRepository messages;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> threads = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> queues = <Map<String, dynamic>>[
    <String, dynamic>{'value': 'general', 'label': 'Front desk'},
    <String, dynamic>{'value': 'clinical', 'label': 'Clinical'},
    <String, dynamic>{'value': 'billing', 'label': 'Billing'},
  ];
  String filter = 'all';
  String query = '';
  int unreadCount = 0;
  String? error;
  bool loading = true;
  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Map<String, dynamic>> _asMapList(dynamic raw) {
    final list = raw is List ? raw : const [];
    return <Map<String, dynamic>>[
      for (final row in list)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }

  Future<void> _load() async {
    setState(() {
      if (threads.isEmpty) loading = true;
      refreshing = threads.isNotEmpty;
      error = null;
    });

    try {
      final data = await widget.messages.inbox();
      final rows = _asMapList(data['threads']);
      final queueRows = _asMapList(data['queues']);

      if (!mounted) return;
      setState(() {
        threads = rows;
        if (queueRows.isNotEmpty) queues = queueRows;
        unreadCount = (data['unread_messages'] as num?)?.toInt() ??
            rows.where((t) => t['unread'] == true).length;
        loading = false;
        refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
        refreshing = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visible {
    return <Map<String, dynamic>>[
      for (final thread in threads)
        if (_matchesFilter(thread)) thread,
    ];
  }

  bool _matchesFilter(Map<String, dynamic> thread) {
    final unread = thread['unread'] == true;
    final queue = thread['queue']?.toString() ?? '';
    final subject = (thread['subject']?.toString() ?? '').toLowerCase();
    final preview = (thread['preview']?.toString() ?? '').toLowerCase();
    final haystack = '$subject $preview';

    if (filter == 'unread' && !unread) return false;
    if (filter != 'all' && filter != 'unread' && queue != filter) return false;
    if (query.trim().isNotEmpty && !haystack.contains(query.trim().toLowerCase())) {
      return false;
    }
    return true;
  }

  Future<void> _openCompose() async {
    await AppHaptics.selection();
    if (!mounted) return;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ComposeSheet(
        messages: widget.messages,
        queues: queues,
      ),
    );
    if (sent == true && mounted) await _load();
  }

  Future<void> _openThread(Map<String, dynamic> thread) async {
    await AppPageRoute.push(
      context,
      MessageThreadScreen(
        messages: widget.messages,
        threadId: thread['id'] as int,
        subject: thread['subject']?.toString(),
        queueLabel: thread['queue_label']?.toString(),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return DashboardBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 88),
          child: FloatingActionButton.extended(
            onPressed: _openCompose,
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            elevation: 2,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Compose', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inbox',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Secure messages with your clinic',
                            style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    if (refreshing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                      )
                    else if (unreadCount > 0)
                      StatusPill(label: '$unreadCount unread', tone: PillTone.info),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TextField(
                  onChanged: (value) => setState(() => query = value),
                  style: const TextStyle(fontSize: 14, color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Search conversations',
                    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted, size: 20),
                    filled: true,
                    fillColor: AppColors.fieldFill,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.teal, width: 1.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: filter == 'all',
                      onTap: () => setState(() => filter = 'all'),
                    ),
                    _FilterChip(
                      label: 'Unread',
                      selected: filter == 'unread',
                      onTap: () => setState(() => filter = 'unread'),
                    ),
                    ...queues.map((queue) {
                      final value = queue['value']?.toString() ?? '';
                      return _FilterChip(
                        label: queue['label']?.toString() ?? value,
                        selected: filter == value,
                        onTap: () => setState(() => filter = value),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.teal,
                  onRefresh: _load,
                  child: loading && threads.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                      : error != null && threads.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              children: [
                                Text(error!, style: const TextStyle(color: AppColors.danger)),
                                const SizedBox(height: 12),
                                FilledButton(onPressed: _load, child: const Text('Try again')),
                              ],
                            )
                          : visible.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                                  children: [
                                    Icon(Icons.chat_bubble_outline_rounded, size: 42, color: AppColors.teal.withValues(alpha: 0.45)),
                                    const SizedBox(height: 14),
                                    Text(
                                      query.isNotEmpty || filter != 'all'
                                          ? 'No conversations match this filter.'
                                          : 'No messages yet',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Message front desk, clinical, or billing — your clinic replies here.',
                                      style: TextStyle(color: AppColors.muted, height: 1.4),
                                    ),
                                    const SizedBox(height: 16),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: FilledButton.tonal(
                                        onPressed: _openCompose,
                                        child: const Text('Start a conversation'),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                                  itemCount: visible.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                                  itemBuilder: (context, index) {
                                    final thread = visible[index];
                                    return _ThreadTile(
                                      thread: thread,
                                      onTap: () => _openThread(thread),
                                    );
                                  },
                                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
        selectedColor: AppColors.tealMist,
        backgroundColor: AppColors.fieldFill,
        side: BorderSide(color: selected ? AppColors.teal.withValues(alpha: 0.35) : AppColors.line),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.tealDeep : AppColors.ink,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.onTap});

  final Map<String, dynamic> thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = thread['unread'] == true;
    final subject = thread['subject']?.toString() ?? 'Conversation';
    final preview = thread['preview']?.toString() ?? 'No preview yet';
    final queue = thread['queue_label']?.toString() ?? 'Clinic';
    final time = _relativeTime(thread['last_message_at_iso']?.toString());
    final initial = subject.trim().isEmpty ? 'C' : subject.trim().substring(0, 1).toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: unread ? AppColors.tealMist.withValues(alpha: 0.55) : AppColors.fieldFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: unread ? AppColors.teal.withValues(alpha: 0.18) : AppColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: unread ? AppColors.teal : AppColors.tealMist,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: unread ? Colors.white : AppColors.teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 14.5,
                              color: AppColors.ink,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                            color: unread ? AppColors.tealSoft : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        StatusPill(label: queue, tone: PillTone.neutral),
                        const SizedBox(width: 6),
                        StatusPill(
                          label: _statusLabel(thread['status']?.toString()),
                          tone: unread ? PillTone.info : PillTone.neutral,
                        ),
                        if (unread) ...[
                          const Spacer(),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String? status) {
    return switch (status) {
      'waiting_staff' => 'Awaiting clinic',
      'waiting_patient' => 'Your turn',
      'closed' => 'Closed',
      _ => (status ?? 'Open').replaceAll('_', ' '),
    };
  }
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet({
    required this.messages,
    required this.queues,
  });

  final MessagesRepository messages;
  final List<Map<String, dynamic>> queues;

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  late String queue;
  final subject = TextEditingController();
  final body = TextEditingController();
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    queue = widget.queues.first['value']?.toString() ?? 'general';
  }

  @override
  void dispose() {
    subject.dispose();
    body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (subject.text.trim().isEmpty || body.text.trim().isEmpty) {
      setState(() => error = 'Add a subject and message before sending.');
      return;
    }

    await AppHaptics.action();
    setState(() {
      busy = true;
      error = null;
    });

    try {
      await widget.messages.start(
        queue: queue,
        subject: subject.text.trim(),
        body: body.text.trim(),
      );
      await AppHaptics.success();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Message sent to your clinic.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'New message',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose a department and send a secure note.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.queues.map((item) {
                  final value = item['value']?.toString() ?? '';
                  final selected = queue == value;
                  return ChoiceChip(
                    label: Text(item['label']?.toString() ?? value),
                    selected: selected,
                    onSelected: busy ? null : (_) => setState(() => queue = value),
                    selectedColor: AppColors.tealMist,
                    labelStyle: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.tealDeep : AppColors.ink,
                      fontSize: 12.5,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subject,
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration('Subject'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: body,
                maxLines: 5,
                decoration: _fieldDecoration('Write your message'),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : _send,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                      child: Text(busy ? 'Sending…' : 'Send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.cream,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.teal, width: 1.4),
      ),
    );
  }
}

class MessageThreadScreen extends StatefulWidget {
  const MessageThreadScreen({
    super.key,
    required this.messages,
    required this.threadId,
    this.subject,
    this.queueLabel,
  });

  final MessagesRepository messages;
  final int threadId;
  final String? subject;
  final String? queueLabel;

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final body = TextEditingController();
  final scroll = ScrollController();
  Map<String, dynamic>? thread;
  String? error;
  bool loading = true;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    body.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await widget.messages.show(widget.threadId);
      if (!mounted) return;
      setState(() {
        thread = data['thread'] as Map<String, dynamic>?;
        error = null;
        loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) {
          scroll.jumpTo(scroll.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> _reply() async {
    final text = body.text.trim();
    if (text.isEmpty) return;

    await AppHaptics.action();
    setState(() => busy = true);
    try {
      final data = await widget.messages.reply(widget.threadId, text);
      await AppHaptics.success();
      body.clear();
      if (!mounted) return;
      setState(() {
        thread = data['thread'] as Map<String, dynamic>? ?? thread;
        error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) {
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = <Map<String, dynamic>>[
      for (final row in ((thread?['messages'] as List<dynamic>?) ?? const []))
        if (row is Map) Map<String, dynamic>.from(row),
    ];
    final subject = thread?['subject']?.toString() ?? widget.subject ?? 'Conversation';
    final queue = thread?['queue_label']?.toString() ?? widget.queueLabel;

    return DashboardBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              if (queue != null)
                Text(
                  queue,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final fromClinic = message['sender_role'] == 'staff';
                        return _MessageBubble(
                          fromClinic: fromClinic,
                          body: message['body']?.toString() ?? '',
                          author: message['author']?.toString(),
                          time: _relativeTime(message['created_at_iso']?.toString()),
                        );
                      },
                    ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                12,
                10,
                12,
                10 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.fieldFill,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: body,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Write a reply…',
                        filled: true,
                        fillColor: AppColors.cream,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.teal, width: 1.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: busy ? null : _reply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.fromClinic,
    required this.body,
    required this.time,
    this.author,
  });

  final bool fromClinic;
  final String body;
  final String time;
  final String? author;

  @override
  Widget build(BuildContext context) {
    final align = fromClinic ? Alignment.centerLeft : Alignment.centerRight;
    final color = fromClinic ? AppColors.fieldFill : AppColors.teal;
    final textColor = fromClinic ? AppColors.ink : Colors.white;
    final metaColor = fromClinic ? AppColors.muted : Colors.white70;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(fromClinic ? 5 : 16),
              bottomRight: Radius.circular(fromClinic ? 16 : 5),
            ),
            border: fromClinic ? Border.all(color: AppColors.line) : null,
            boxShadow: fromClinic
                ? null
                : const [
                    BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fromClinic ? (author?.isNotEmpty == true ? author! : 'Clinic') : 'You',
                style: TextStyle(
                  color: metaColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(color: textColor, height: 1.4, fontSize: 14.5),
              ),
              const SizedBox(height: 6),
              Text(
                time,
                style: TextStyle(color: metaColor, fontSize: 10.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _relativeTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '';

  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24 && now.day == dt.day) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }
  if (diff.inDays < 7) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }
  return '${dt.month}/${dt.day}';
}
