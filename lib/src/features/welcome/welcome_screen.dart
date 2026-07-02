import 'package:flutter/material.dart';

import '../../shared/widgets/pressable_scale.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/welcome_health.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000000),
                  Color(0x00000000),
                  Color(0x66000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 720;

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: compact ? 38 : 92),
                        _WelcomeLogo(compact: compact),
                        SizedBox(height: compact ? 40 : 118),
                        _WelcomePanel(
                          compact: compact,
                          onGetStarted: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeLogo extends StatelessWidget {
  const _WelcomeLogo({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'MediCare',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFF8F2E9),
            fontSize: compact ? 38 : 46,
            height: 1,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.35),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: compact ? 70 : 86,
          height: compact ? 70 : 86,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.56),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.favorite_border,
            color: Colors.white,
            size: compact ? 36 : 44,
          ),
        ),
      ],
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.compact, required this.onGetStarted});

  final bool compact;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(32, compact ? 28 : 42, 32, 24),
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Text(
              'MediCare helps users manage their medication schedules and monitor their health conditions. By providing medication reminders, intake tracking, health reports, and simple health suggestions, we support better medication adherence and promote healthier living.',
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: compact ? 16 : 20,
                height: compact ? 1.35 : 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: compact ? 22 : 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: PressableScale(
              child: FilledButton(
                onPressed: onGetStarted,
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(compact ? 52 : 58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('Get Started !'),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 118,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
