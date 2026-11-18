import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'navigation/main_shell.dart';
import 'providers/auth_provider.dart';
import 'providers/navegacion_provider.dart';
import 'screens/auth/bienvenida_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'services/almacen_sesion.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'utils/mensajes.dart';

/// Llaves globales para navegar y mostrar mensajes desde fuera de una pantalla
/// (por ejemplo, cuando la sesión expira en medio de cualquier pantalla).
final claveNavegador = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carga los nombres de días y meses en español para intl
  await initializeDateFormatting('es_CO');

  // Un solo ApiService para toda la app (comparte el token)
  final api = ApiService();
  runApp(LifeOSApp(api: api, almacen: AlmacenSesion()));
}

/// Raíz de la app: crea los providers, aplica el tema oscuro y el idioma español.
class LifeOSApp extends StatelessWidget {
  const LifeOSApp({super.key, required this.api, required this.almacen});

  final ApiService api;
  final AlmacenSesion almacen;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavegacionProvider()),
        ChangeNotifierProvider(
          create: (contexto) {
            final auth = AuthProvider(api: api, servicio: AuthService(api), almacen: almacen);
            // Al cerrar sesión: cerrar las pantallas abiertas y volver a Mi Día
            auth.alCerrarSesion = () {
              claveNavegador.currentState?.popUntil((ruta) => ruta.isFirst);
              contexto.read<NavegacionProvider>().reiniciar();
            };
            auth.cargarSesionGuardada();
            return auth;
          },
        ),
      ],
      child: MaterialApp(
        title: 'LifeOS',
        navigatorKey: claveNavegador,
        debugShowCheckedModeBanner: false,
        theme: crearTemaOscuro(),
        darkTheme: crearTemaOscuro(),
        themeMode: ThemeMode.dark,
        locale: const Locale('es', 'CO'),
        supportedLocales: const [Locale('es', 'CO'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const RaizSesion(),
      ),
    );
  }
}

/// Decide qué mostrar según la sesión: Splash, Bienvenida o la app principal.
class RaizSesion extends StatelessWidget {
  const RaizSesion({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Si hay un aviso (por ejemplo «Tu sesión expiró»), se muestra una vez
    if (auth.estado == EstadoSesion.sinSesion && auth.avisoPendiente != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final aviso = auth.tomarAviso();
        if (aviso != null && context.mounted) mostrarMensaje(context, aviso, error: true);
      });
    }

    // AnimatedSwitcher: transición corta entre Splash, Bienvenida y la app
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: switch (auth.estado) {
        EstadoSesion.iniciando || EstadoSesion.errorConexion => const SplashScreen(),
        EstadoSesion.sinSesion => const BienvenidaScreen(),
        EstadoSesion.conSesion => const MainShell(),
      },
    );
  }
}
