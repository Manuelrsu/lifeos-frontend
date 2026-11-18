import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme/app_theme.dart';
import 'widgets/logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carga los nombres de días y meses en español para intl
  await initializeDateFormatting('es_CO');
  runApp(const LifeOSApp());
}

/// Raíz de la app: tema oscuro global e idioma español.
class LifeOSApp extends StatelessWidget {
  const LifeOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeOS',
      debugShowCheckedModeBanner: false,
      theme: crearTemaOscuro(),
      darkTheme: crearTemaOscuro(),
      themeMode: ThemeMode.dark,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Pantalla provisional de la Fase 2; en la Fase 3 se reemplaza por el Splash
      home: const Scaffold(body: Center(child: LogoLifeOS())),
    );
  }
}
