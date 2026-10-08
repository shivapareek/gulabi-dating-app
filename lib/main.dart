import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'config.dart';
import 'data/demo_repo.dart';
import 'data/firebase_repo.dart';
import 'data/repo.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  if (AppConfig.hasFirebase) {
    try {
      await Firebase.initializeApp(options: AppConfig.firebaseOptions);
      Repo.instance = FirebaseRepo();
    } catch (_) {
      Repo.instance = DemoRepo();
    }
  } else {
    Repo.instance = DemoRepo();
  }
  await app.init();
  runApp(const GulabiApp());
}

class GulabiApp extends StatelessWidget {
  const GulabiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (_, __) => MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: app.themeMode,
        home: const Gate(),
      ),
    );
  }
}

/// Decides the first screen: welcome, profile setup or the main app.
class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    Widget next;
    if (Repo.instance.uid == null) {
      next = const WelcomeScreen();
    } else {
      try {
        await app.loadMe();
      } catch (_) {}
      next = (app.me?.isComplete ?? false)
          ? const HomeShell()
          : const OnboardingScreen();
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(next));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Brand.gradient),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Brand.pink, size: 56),
              ),
              const SizedBox(height: 18),
              const Text(AppConfig.appName,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
              const Text('Pink City ka pyaar',
                  style: TextStyle(color: Colors.white70, fontSize: 15)),
            ]),
          ),
        ),
      ),
    );
  }
}
