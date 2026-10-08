import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../data/repo.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  String? _verificationId;
  bool _loading = false;

  Future<void> _send() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      toast(context, 'Enter a valid 10 digit mobile number');
      return;
    }
    setState(() => _loading = true);
    await Repo.instance.sendOtp(
      '+91$digits',
      onCodeSent: (id) {
        if (!mounted) return;
        setState(() {
          _verificationId = id;
          _loading = false;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _loading = false);
        toast(context, e);
      },
      onAutoVerified: _afterLogin,
    );
  }

  Future<void> _verify() async {
    if (_otp.text.length != 6) return;
    setState(() => _loading = true);
    try {
      await Repo.instance.verifyOtp(_verificationId!, _otp.text);
      await _afterLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      toast(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _afterLogin() async {
    await app.loadMe();
    if (!mounted) return;
    final next = (app.me?.isComplete ?? false)
        ? const HomeShell()
        : const OnboardingScreen();
    Navigator.of(context)
        .pushAndRemoveUntil(fadeRoute(next), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final otpStep = _verificationId != null;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                otpStep ? 'Enter the code' : 'What\'s your number?',
                key: ValueKey(otpStep),
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              otpStep
                  ? 'We sent a 6 digit code to +91 ${_phone.text}'
                  : 'We will send you a one-time code. Your number is never shown on your profile.',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 32),
            if (!otpStep)
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 20, letterSpacing: 1.5),
                decoration: const InputDecoration(
                  counterText: '',
                  prefixIcon: Padding(
                    padding: EdgeInsets.fromLTRB(18, 14, 8, 14),
                    child: Text('🇮🇳 +91', style: TextStyle(fontSize: 18)),
                  ),
                  hintText: '98765 43210',
                ),
              )
            else
              TextField(
                controller: _otp,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  if (v.length == 6) _verify();
                },
                style: const TextStyle(
                    fontSize: 30, letterSpacing: 14, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(counterText: '', hintText: '••••••'),
              ),
            const SizedBox(height: 28),
            GradientButton(
              otpStep ? 'Verify' : 'Send code',
              loading: _loading,
              onTap: otpStep ? _verify : _send,
            ),
            if (otpStep)
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                          _verificationId = null;
                          _otp.clear();
                        }),
                child: const Text('Change number',
                    style: TextStyle(color: Brand.pink)),
              ),
          ],
        ),
      ),
    );
  }
}
