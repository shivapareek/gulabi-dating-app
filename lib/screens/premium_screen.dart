import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../widgets/common.dart';

class PremiumScreen extends StatefulWidget {
  final String? reason;
  const PremiumScreen({super.key, this.reason});
  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _plan = 1;
  bool _busy = false;

  static const _plans = [
    ('1 month', 499, null),
    ('3 months', 999, 'Most popular · save 33%'),
    ('12 months', 2499, 'Best value · save 58%'),
  ];

  static const _features = [
    (Icons.all_inclusive_rounded, 'Unlimited likes'),
    (Icons.favorite_rounded, 'See who likes you'),
    (Icons.replay_rounded, 'Rewind your last swipe'),
    (Icons.star_rounded, '5 Super Likes every day'),
    (Icons.bolt_rounded, 'Boost: be the top profile in Jaipur'),
    (Icons.tune_rounded, 'Advanced filters'),
  ];

  Future<void> _buy() async {
    if (!Repo.instance.isDemo) {
      toast(context,
          'Payments will go live once the Razorpay account is connected.');
      return;
    }
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 900));
    final me = app.me!;
    me.premium = true;
    await app.saveMe(me);
    if (!mounted) return;
    setState(() => _busy = false);
    toast(context, '👑 Welcome to Gulabi Gold (demo)');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A1405), Color(0xFF120A10)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                          gradient: Brand.goldGradient, shape: BoxShape.circle),
                      child: const Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 44),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('Gulabi Gold',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800)),
                  ),
                  if (widget.reason != null) ...[
                    const SizedBox(height: 6),
                    Text(widget.reason!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Brand.gold)),
                  ],
                  const SizedBox(height: 24),
                  ..._features.map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(children: [
                          Icon(f.$1, color: Brand.gold),
                          const SizedBox(width: 14),
                          Text(f.$2,
                              style: const TextStyle(color: Colors.white, fontSize: 15)),
                        ]),
                      )),
                  const SizedBox(height: 22),
                  ...List.generate(_plans.length, (i) {
                    final p = _plans[i];
                    final sel = i == _plan;
                    return GestureDetector(
                      onTap: () => setState(() => _plan = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: sel ? Brand.gold.withOpacity(0.14) : Colors.white10,
                          border: Border.all(
                              color: sel ? Brand.gold : Colors.white12, width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.$1,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700)),
                                  if (p.$3 != null)
                                    Text(p.$3!,
                                        style: const TextStyle(
                                            color: Brand.gold, fontSize: 12)),
                                ]),
                          ),
                          Text('₹${p.$2}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                        ]),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: GradientButton(
                app.premium ? 'You are Gold 👑' : 'Continue · ₹${_plans[_plan].$2}',
                gradient: Brand.goldGradient,
                loading: _busy,
                onTap: app.premium ? null : _buy,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
