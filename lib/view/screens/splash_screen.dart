import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supporthive1/view/sign_in_screen.dart';

void main() {
  runApp(const SupportHiveApp());
}

class SupportHiveApp extends StatelessWidget {
  const SupportHiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SupportHive',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

/// Brand colors - adjust these to exactly match your real assets/theme.
class HiveColors {
  static const icon = Color(0xFF2E6657);
  static const tagline = Color(0xFF3B5F46);
  static const gradientTop = Color(0xFFF4F2E8); // matches sign-in background
  static const gradientBottom = Color(0xFFACCDB0);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _rise;

  // Drives the looping breathing pulse, started once the entrance finishes.
  late final AnimationController _breathController;
  late final Animation<double> _breathScale;
  late final Animation<double> _breathOpacity;

  static const _introDuration = Duration(milliseconds: 1300);
  // One direction of the breath (in OR out). repeat(reverse:true) means a
  // full in-and-out cycle takes 2x this. Must be well under
  // _holdBeforeNavigate or you'll never see it complete a cycle.
  static const _breathDuration = Duration(milliseconds: 1100);
  // How long to hold on the finished splash before navigating away.
  static const _holdBeforeNavigate = Duration(milliseconds: 3000);

  @override
  void initState() {
    super.initState();

    // Make the status bar transparent so the gradient runs edge-to-edge
    // instead of having a flat-colored bar across the top.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // dark icons on light bg
      ),
    );

    _controller = AnimationController(vsync: this, duration: _introDuration);

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _rise = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _breathController = AnimationController(vsync: this, duration: _breathDuration);
    _breathScale = Tween<double>(begin: 1.0, end: 1.16).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _breathOpacity = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    // Respect the device's "reduce motion" / "remove animations"
    // accessibility setting - some people find continuous motion
    // uncomfortable, especially relevant for a wellbeing app.
    final reduceMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;

    if (reduceMotion) {
      // Jump straight to the fully-revealed state, no entrance animation
      // and no breathing loop - just hold, then navigate.
      _controller.value = 1.0;
      _scheduleNavigation();
    } else {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _breathController.repeat(reverse: true);
          _scheduleNavigation();
        }
      });
      _controller.forward();
    }
  }

  /// Put your real startup work here - checking a saved auth token,
  /// warming up a database, loading remote config, etc. The splash won't
  /// navigate away until both this AND the minimum hold time below have
  /// finished, whichever takes longer.
  Future<void> _appInit() async {
    // TODO: replace with real initialization logic.
    await Future<void>.value();
  }

  void _scheduleNavigation() {
    final minimumHold = Future<void>.delayed(_holdBeforeNavigate);
    final appReady = _appInit();

    Future.wait([minimumHold, appReady]).then((_) {
      if (!mounted) return;
      // TODO: replace _PlaceholderSignIn with your real sign-in route.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [HiveColors.gradientTop, HiveColors.gradientBottom],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _rise,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SUPPORTHIVE',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: HiveColors.icon,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _breathController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _breathOpacity.value,
                        child: Transform.scale(
                          scale: _breathScale.value,
                          child: child,
                        ),
                      );
                    },
                    
                    child: Image.asset(
                      // Icon-only asset, no curved text baked in.
                      'assets/images/logo_icon.png',
                      width: 96,
                      height: 96,
                    ),
                  ),
                  const SizedBox(height: 14), 
                  
                  const Text(
                    'Relax, Recharge, Reflect',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: HiveColors.tagline,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// /// Stand-in destination so this file runs on its own.
// class _PlaceholderSignIn extends StatelessWidget {
//   const _PlaceholderSignIn();

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(child: Text('Sign-in screen placeholder')),
//     );
//   }
// }