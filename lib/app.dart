import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/app_state.dart';
import 'screens/home_shell.dart';
import 'screens/profile_form_screen.dart';
import 'theme.dart';

class DanaNikahApp extends StatelessWidget {
  const DanaNikahApp({super.key});

  @override
  Widget build(BuildContext context) {
    final setupDone =
        context.select<AppState, bool>((s) => s.profile.setupDone);
    return MaterialApp(
      title: 'Dana Nikah',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: setupDone
          ? const HomeShell()
          : ColoredBox(
              color: AppColors.cream,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: const ProfileFormScreen(isOnboarding: true),
                ),
              ),
            ),
    );
  }
}
