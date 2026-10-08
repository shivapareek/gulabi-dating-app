import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/repo.dart';
import '../models.dart';
import 'common.dart';

/// Shows report / block options. Returns true if the person was blocked.
Future<bool> showSafetyMenu(BuildContext context, UserProfile other) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        ListTile(
          leading: const Icon(Icons.flag_rounded, color: Colors.orange),
          title: Text('Report ${other.name}'),
          subtitle: const Text('Fake profile, harassment, spam, underage...'),
          onTap: () => Navigator.pop(context, 'report'),
        ),
        ListTile(
          leading: const Icon(Icons.block_rounded, color: Colors.redAccent),
          title: Text('Block ${other.name}'),
          subtitle: const Text('They will not see you and cannot message you'),
          onTap: () => Navigator.pop(context, 'block'),
        ),
        const SizedBox(height: 10),
      ]),
    ),
  );
  if (!context.mounted) return false;
  if (action == 'report') {
    await _report(context, other);
    return false;
  }
  if (action == 'block') {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Block ${other.name}?'),
        content: const Text('You will be unmatched and will not see each other again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Block', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) {
      await Repo.instance.block(app.me!, other.uid);
      if (context.mounted) toast(context, '${other.name} has been blocked');
      return true;
    }
  }
  return false;
}

Future<void> _report(BuildContext context, UserProfile other) async {
  const reasons = [
    'Fake profile / catfish',
    'Inappropriate photos',
    'Harassment or abuse',
    'Spam or scam',
    'Looks under 18',
    'Something else',
  ];
  String reason = reasons.first;
  final details = TextEditingController();
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, set) => AlertDialog(
        title: Text('Report ${other.name}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ...reasons.map((r) => RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: r,
                  groupValue: reason,
                  title: Text(r),
                  onChanged: (v) => set(() => reason = v!),
                )),
            TextField(
              controller: details,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Tell us more (optional)'),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send report')),
        ],
      ),
    ),
  );
  if (sent == true) {
    await Repo.instance.report(other.uid, reason, details.text.trim());
    if (context.mounted) {
      toast(context, 'Thanks. Our safety team will review this within 24 hours.');
    }
  }
}
