import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'navigation/main_shell.dart';
import 'providers/auth_provider.dart';
import 'providers/habitos_provider.dart';
import 'providers/mi_dia_provider.dart';
import 'providers/navegacion_provider.dart';
import 'providers/preferencias_provider.dart';
import 'providers/salud_provider.dart';
import 'providers/smartstudy_provider.dart';
import 'screens/auth/bienvenida_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'services/almacen_sesion.dart';
import 'services/api_service.dart';
import 'services/servicios.dart';
import 'theme/app_theme.dart';
import 'utils/mensajes.dart';

/// Llave global del navegador: permite cerrar todas las pantallas abiertas
/// cuando la sesión se cierra o expira, desde fuera de cualquier pantalla.
final claveNavegador = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Carga los nombres de días y meses en español para intl
  await initializeDateFormatting('es_CO');

  // Un solo ApiService para toda la app (comparte el token)
  runApp(LifeOSApp(servicios: Servicios(ApiService()), almacen: AlmacenSesion()));
}

/// Raíz de la app: registra servicios y providers, aplica el tema oscuro y el español.
class LifeOSApp extends StatelessWidget {
  const LifeOSApp({super.key, required this.servicios, required this.almacen});

  final Servicios servicios;
  final AlmacenSesion almacen;

  @override
  Widget build(BuildContext context) {
    final s = servicios;
    return MultiProvider(
      providers: [
        // Servicios (sin estado): las pantallas los leen con context.read<...>()
        Provider.value(value: s.auth),
        Provider.value(value: s.smartStudy),
        Provider.value(value: s.habitos),
        Provider.value(value: s.salud),
        // Estado de la app (ChangeNotifier): las pantallas se redibujan cuando cambia
        ChangeNotifierProvider(create: (_) => NavegacionProvider()),
        ChangeNotifierProvider(create: (_) => PreferenciasProvider(s.preferencias)..cargar()),
        ChangeNotifierProvider(
          create: (_) => MiDiaProvider(
            servicio: s.miDia,
            smartStudy: s.smartStudy,
            habitos: s.habitos,
            salud: s.salud,
            preferencias: s.preferencias,
          ),
        ),
        ChangeNotifierProvider(create: (_) => SmartStudyProvider(servicio: s.smartStudy, preferencias: s.preferencias)),
        ChangeNotifierProvider(create: (_) => HabitosProvider(s.habitos)),
        ChangeNotifierProvider(create: (_) => SaludProvider(s.salud)),
        // AuthProvider va al final para poder limpiar a los demás al cerrar sesión
        ChangeNotifierProvider(
          create: (contexto) {
            final auth = AuthProvider(api: s.api, servicio: s.auth, almacen: almacen);
            auth.alCerrarSesion = () {
              claveNavegador.currentState?.popUntil((ruta) => ruta.isFirst);
              contexto.read<NavegacionProvider>().reiniciar();
              contexto.read<MiDiaProvider>().limpiar();
              contexto.read<SmartStudyProvider>().limpiar();
              contexto.read<HabitosProvider>().limpiar();
              contexto.read<SaludProvider>().limpiar();
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
