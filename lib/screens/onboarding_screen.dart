import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _pages = const [
    _Page(emoji: '🥗', title: 'Track Every\nCalorie', sub: 'Log meals in seconds with our smart food database of 28+ foods with full macro breakdown.', color: AppColors.primary, bg: AppColors.primaryLight),
    _Page(emoji: '🏋️', title: 'Train\nSmarter', sub: 'Follow guided workouts with step-by-step instructions and a built-in exercise timer with rest countdown.', color: AppColors.blue, bg: AppColors.blueLight),
    _Page(emoji: '🤖', title: 'AI Nutrition\nCoach', sub: 'Get personalized meal recommendations and instant answers from your AI-powered nutrition coach.', color: AppColors.purple, bg: AppColors.purpleLight),
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: Column(children: [
        Align(alignment: Alignment.topRight, child: Padding(padding: const EdgeInsets.all(16),
          child: TextButton(onPressed: _done, child: Text('Skip', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500))))),
        Expanded(child: PageView.builder(
          controller: _ctrl, itemCount: _pages.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 160, height: 160, decoration: BoxDecoration(color: _pages[i].bg, shape: BoxShape.circle), child: Center(child: Text(_pages[i].emoji, style: const TextStyle(fontSize: 72)))),
              const SizedBox(height: 48),
              Text(_pages[i].title, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.1, letterSpacing: -1)),
              const SizedBox(height: 16),
              Text(_pages[i].sub, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSecondary, height: 1.6)),
            ]),
          ),
        )),
        Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 32), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _page == i ? 24 : 8, height: 8,
            decoration: BoxDecoration(color: _page == i ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(4)),
          ))),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _page < 2 ? () => _ctrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut) : _done,
            child: Text(_page < 2 ? 'Continue' : 'Get Started'),
          )),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('Already have an account? ', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
            GestureDetector(onTap: () { Hive.box('settings').put('onboardingDone', true); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); },
              child: Text('Sign In', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600))),
          ]),
        ])),
      ])),
    );
  }

  void _done() {
    Hive.box('settings').put('onboardingDone', true);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }
}

class _Page {
  final String emoji, title, sub;
  final Color color, bg;
  const _Page({required this.emoji, required this.title, required this.sub, required this.color, required this.bg});
}
