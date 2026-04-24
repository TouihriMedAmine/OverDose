import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({
    super.key,
    required this.onGetStarted,
  });

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          children: [
            Center(
              child: SizedBox(
                height: 66,
                child: !kIsWeb
                    ? Image.file(
                        _projectLogoFile(),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _logoFallback(context),
                      )
                    : _logoFallback(context),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Simulate the Effects of\nDaily Chemicals',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 14),
            Text(
              'Discover the impact of endocrine disruptors hidden in food, cosmetics, cleaning products, and everything we use daily.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 28),
            Center(
              child: SizedBox(
                width: 290,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5A9E54), Color(0xFF2E8B57)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x332E8B57),
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: FilledButton(
                    onPressed: onGetStarted,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 34 / 2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      emoji: '🧪',
                      value: '3500+',
                      label: 'Endocrine\nDisruptors',
                      valueColor: Color(0xFF2E7D32),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: VerticalDivider(thickness: 1),
                  ),
                  Expanded(
                    child: _StatCell(
                      emoji: '☠',
                      value: '8000+',
                      label: 'Toxic\nProducts',
                      valueColor: Color(0xFFC62828),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Row(
              children: [
                Expanded(child: _CategoryCell(emoji: '🧃', label: 'Food')),
                Expanded(child: _CategoryCell(emoji: '🧴', label: 'Cosmetics')),
                Expanded(child: _CategoryCell(emoji: '🧼', label: 'Cleaning')),
                Expanded(child: _CategoryCell(emoji: '💊', label: 'Supplements')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  File _projectLogoFile() {
    // App is launched from `mobile/`; logo is at repo-root `assets/logo.png`.
    final base = Directory.current.path;
    return File('$base${Platform.pathSeparator}..${Platform.pathSeparator}assets${Platform.pathSeparator}logo.png');
  }

  Widget _logoFallback(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              letterSpacing: -0.5,
            ),
        children: const [
          TextSpan(
            text: 'Over ',
            style: TextStyle(color: Color(0xFF2E7D32)),
          ),
          TextSpan(
            text: 'D',
            style: TextStyle(color: Color(0xFFC62828)),
          ),
          TextSpan(
            text: '☠',
            style: TextStyle(color: Color(0xFFC62828)),
          ),
          TextSpan(
            text: 'se',
            style: TextStyle(color: Color(0xFFC62828)),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.emoji,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String emoji;
  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                height: 1.1,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.emoji,
    required this.label,
  });

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 34),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
