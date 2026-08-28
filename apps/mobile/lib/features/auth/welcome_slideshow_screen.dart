import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/app_store.dart';
import 'welcome_slides.dart';

class WelcomeSlideshowScreen extends StatefulWidget {
  const WelcomeSlideshowScreen({super.key});

  @override
  State<WelcomeSlideshowScreen> createState() => _WelcomeSlideshowScreenState();
}

class _WelcomeSlideshowScreenState extends State<WelcomeSlideshowScreen> {
  final _controller = PageController();
  int _index = 0;
  Timer? _auto;

  @override
  void initState() {
    super.initState();
    _restartAuto();
  }

  @override
  void dispose() {
    _auto?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartAuto() {
    _auto?.cancel();
    _auto = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      if (!mounted) return;
      if (_index >= welcomeSlides.length - 1) {
        _finish();
        return;
      }
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _finish() {
    _auto?.cancel();
    if (!mounted) return;
    final store = context.read<AppStore>();
    context.go(store.homeRouteForRole());
  }

  @override
  Widget build(BuildContext context) {
    final last = _index >= welcomeSlides.length - 1;
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: welcomeSlides.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _restartAuto();
            },
            itemBuilder: (context, i) {
              final slide = welcomeSlides[i];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    slide.asset,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Color(0x99000000),
                          Color(0xCC000000),
                        ],
                        stops: [0.0, 0.45, 0.72, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 28,
                    right: 28,
                    bottom: 88 + bottomPad,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (i == 0)
                          Text(
                            'Ludmila & Dyego',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          ),
                        if (i == 0) const SizedBox(height: 10),
                        Text(
                          slide.phrase,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cormorantGaramond(
                            color: Colors.white,
                            fontSize: i == 1 ? 36 : 28,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 48,
                          height: 1.5,
                          color: AppColors.primary.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: topPad + 8,
            right: 12,
            child: TextButton(
              onPressed: _finish,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.92),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Text(
                'Pular',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20 + bottomPad,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(welcomeSlides.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3.5),
                      width: active ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
                if (last) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Continuar',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
