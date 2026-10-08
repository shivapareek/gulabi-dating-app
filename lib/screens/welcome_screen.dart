import 'package:flutter/material.dart';

import '../config.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _slides = [
    (Icons.location_city_rounded, 'Only Jaipur',
        'Meet people from C-Scheme to Mansarovar. Real people, right in your city.'),
    (Icons.verified_user_rounded, 'Verified & safe',
        'Selfie verification, block and report in one tap. 18+ only.'),
    (Icons.chat_bubble_rounded, 'Match & chat',
        'Swipe, match and start talking instantly with photos and live typing.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 24),
            Row(children: [
              const LogoMark(size: 44),
              const SizedBox(width: 12),
              Text(AppConfig.appName,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ]),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        key: ValueKey(i),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutBack,
                        builder: (_, v, c) => Transform.scale(scale: v, child: c),
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: const BoxDecoration(
                              gradient: Brand.gradient, shape: BoxShape.circle),
                          child: Icon(s.$1, size: 84, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(s.$2,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text(s.$3,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).hintColor)),
                    ],
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.all(4),
                  width: _page == i ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? Brand.pink : Brand.pink.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(
              'Continue with phone number',
              icon: Icons.phone_iphone_rounded,
              onTap: () => Navigator.of(context)
                  .push(fadeRoute(const LoginScreen())),
            ),
            const SizedBox(height: 14),
            Text(
              'By continuing you confirm you are 18+ and agree to our Terms, '
              'Privacy Policy and Community Guidelines.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
            if (Repo.instance.isDemo) ...[
              const SizedBox(height: 8),
              const Text('Demo mode · OTP: 123456',
                  style: TextStyle(color: Brand.coral, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}
