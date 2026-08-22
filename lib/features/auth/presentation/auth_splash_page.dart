import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

class AuthSplashPage extends StatelessWidget {
  const AuthSplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: 'motive, 로그인 상태 확인 중',
            child: const ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SplashMark(),
                  SizedBox(height: 18),
                  Text(
                    'motive',
                    style: TextStyle(
                      color: AppPalette.ink,
                      fontSize: 34,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.4,
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppPalette.blue,
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

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const SizedBox(
        width: 64,
        height: 64,
        child: Icon(Icons.bolt_rounded, color: Colors.white, size: 37),
      ),
    );
  }
}
