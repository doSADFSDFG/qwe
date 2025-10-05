import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/home_shell.dart';
import '../theme/app_theme.dart';
import '../data/database_initializer.dart';

class CalutPosApp extends ConsumerWidget {
  const CalutPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(databaseInitializerProvider).ensureInitialized();

    return MaterialApp(
      title: 'Calut POS',
      debugShowCheckedModeBanner: false,
      theme: buildPosTheme(),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}
