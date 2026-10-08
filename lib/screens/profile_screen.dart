import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'onboarding_screen.dart';
import 'premium_screen.dart';
import 'profile_detail_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  int _completeness() {
    final p = app.me;
    if (p == null) return 0;
    var score = 0;
    if (p.photos.length >= 2) score += 20;
    if (p.photos.length >= 4) score += 10;
    if (p.bio.isNotEmpty) score += 15;
    if (p.job.isNotEmpty) score += 10;
    if (p.education.isNotEmpty) score += 5;
    if (p.interests.length >= 3) score += 15;
    if (p.prompts.isNotEmpty) score += 15;
    if (p.verificationStatus != 'none') score += 10;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final me = app.me;
        if (me == null) return const SizedBox();
        final pct = _completeness();
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              Text('Profile',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              Center(
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 136,
                    height: 136,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: pct / 100),
                      duration: const Duration(milliseconds: 900),
                      builder: (_, v, __) => CircularProgressIndicator(
                        value: v,
                        strokeWidth: 5,
                        color: Brand.pink,
                        backgroundColor: Brand.pink.withOpacity(0.15),
                      ),
                    ),
                  ),
                  Avatar(me.photos.firstOrNull, name: me.name, size: 118),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          gradient: Brand.gradient,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('$pct% complete',
                          style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${me.name}, ${me.age}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (me.verified) ...[const SizedBox(width: 6), const VerifiedBadge()],
                if (me.premium) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.workspace_premium_rounded, color: Brand.gold),
                ],
              ]),
              Center(
                child: Text(me.area, style: TextStyle(color: Theme.of(context).hintColor)),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: _bigBtn(context, Icons.edit_rounded, 'Edit profile', () {
                    Navigator.of(context)
                        .push(fadeRoute(const OnboardingScreen(editing: true)));
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _bigBtn(context, Icons.visibility_rounded, 'Preview', () {
                    Navigator.of(context)
                        .push(fadeRoute(ProfileDetailScreen(p: me, isMe: true)));
                  }),
                ),
              ]),
              const SizedBox(height: 16),
              if (!me.premium)
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).push(fadeRoute(const PremiumScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: Brand.goldGradient,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(children: [
                      Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 38),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Get Gulabi Gold',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17)),
                          Text('See who likes you, unlimited likes & more',
                              style: TextStyle(color: Colors.white, fontSize: 13)),
                        ]),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.white),
                    ]),
                  ),
                ),
              const SizedBox(height: 24),
              _section(context, 'Settings'),
              _tile(context, Icons.dark_mode_rounded, 'Theme',
                  trailing: DropdownButton<ThemeMode>(
                    value: app.themeMode,
                    underline: const SizedBox(),
                    onChanged: (m) => app.setTheme(m!),
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    ],
                  )),
              _section(context, 'Safety'),
              _tile(context, Icons.shield_rounded, 'Dating safety tips',
                  onTap: () => _safetyTips(context)),
              _tile(context, Icons.privacy_tip_rounded, 'Privacy',
                  onTap: () => toast(context,
                      'Your phone number and exact location are never shown to others.')),
              _section(context, 'Account'),
              _tile(context, Icons.logout_rounded, 'Log out', onTap: () async {
                await Repo.instance.signOut();
                app.me = null;
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                      fadeRoute(const WelcomeScreen()), (_) => false);
                }
              }),
              _tile(context, Icons.delete_forever_rounded, 'Delete account',
                  color: Colors.redAccent, onTap: () => _delete(context)),
              const SizedBox(height: 20),
              Center(
                child: Text('Gulabi v1.0${Repo.instance.isDemo ? ' · demo mode' : ''}',
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bigBtn(BuildContext c, IconData i, String t, VoidCallback onTap) =>
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Brand.pink.withOpacity(0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: onTap,
        icon: Icon(i, color: Brand.pink),
        label: Text(t),
      );

  Widget _section(BuildContext c, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
        child: Text(t.toUpperCase(),
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: Theme.of(c).hintColor)),
      );

  Widget _tile(BuildContext c, IconData i, String t,
          {Widget? trailing, VoidCallback? onTap, Color? color}) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(i, color: color ?? Brand.pink),
        title: Text(t, style: TextStyle(color: color)),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded) : null),
        onTap: onTap,
      );

  void _safetyTips(BuildContext context) => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Stay safe on Gulabi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              SizedBox(height: 14),
              Text('• Meet first in a public place like a cafe or mall.'),
              Text('• Tell a friend or family member where you are going.'),
              Text('• Never send money or share OTPs and bank details.'),
              Text('• Keep chatting inside the app until you trust someone.'),
              Text('• Report anyone who makes you uncomfortable. We review every report.'),
              SizedBox(height: 10),
              Text('Emergency: dial 112 · Women helpline: 1091'),
            ]),
          ),
        ),
      );

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'Your profile, matches and messages will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    await Repo.instance.deleteAccount();
    app.me = null;
    if (context.mounted) {
      Navigator.of(context)
          .pushAndRemoveUntil(fadeRoute(const WelcomeScreen()), (_) => false);
    }
  }
}
