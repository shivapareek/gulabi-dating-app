import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final Gradient gradient;
  final IconData? icon;
  const GradientButton(
    this.label, {
    super.key,
    this.onTap,
    this.loading = false,
    this.gradient = Brand.gradient,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Brand.pink.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: enabled ? onTap : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a photo from a network URL or local file, or a branded placeholder.
class Photo extends StatelessWidget {
  final String? url;
  final String name;
  final BoxFit fit;
  const Photo(this.url, {super.key, this.name = '', this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _placeholder();
    if (u.startsWith('file://')) {
      return Image.file(File(u.substring(7)), fit: fit);
    }
    return CachedNetworkImage(
      imageUrl: u,
      fit: fit,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    final palettes = [
      [const Color(0xFFFF3C78), const Color(0xFF7B2FF7)],
      [const Color(0xFFFF7A59), const Color(0xFFFF3C78)],
      [const Color(0xFF7B2FF7), const Color(0xFF3FA9F5)],
      [const Color(0xFFFFB648), const Color(0xFFFF3C78)],
    ];
    final p = palettes[name.hashCode.abs() % palettes.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: p, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.w800,
            color: Colors.white.withOpacity(0.85)),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  final bool online;
  const Avatar(this.url,
      {super.key, required this.name, this.size = 56, this.online = false});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(width: 200, height: 200, child: Photo(url, name: name)),
          ),
        ),
      ),
      if (online)
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: size * 0.24,
            height: size * 0.24,
            decoration: BoxDecoration(
              color: Brand.green,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor, width: 2),
            ),
          ),
        ),
    ]);
  }
}

class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({super.key, this.size = 20});
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.verified_rounded, color: Brand.blue, size: size);
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
}

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );

class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 84});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: Brand.gradient,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: [
            BoxShadow(
                color: Brand.pink.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 12))
          ],
        ),
        child: Icon(Icons.favorite_rounded,
            color: Colors.white, size: size * 0.55),
      );
}
