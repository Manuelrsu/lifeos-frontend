import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/botones.dart';
import '../../widgets/logo.dart';

/// Primera pantalla: el logo mientras se revisa si hay una sesión guardada.
/// Si el servidor no responde, lo dice y permite reintentar o entrar con otra cuenta.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sinConexion = auth.estado == EstadoSesion.errorConexion;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppMedidas.margenPantalla),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LogoLifeOS(tamano: 72),
                const SizedBox(height: 8),
                Text(
                  'Todo tu progreso en una sola aplicación',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textoSecundario),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (!sinConexion)
                  const CircularProgressIndicator()
                else ...[
                  Text(
                    auth.avisoPendiente ?? 'No se pudo conectar con el servidor.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  PillButton(
                    texto: 'Reintentar',
                    icono: Icons.refresh_rounded,
                    onPressed: () => context.read<AuthProvider>().cargarSesionGuardada(),
                  ),
                  const SizedBox(height: 8),
                  PillButton(
                    texto: 'Entrar con otra cuenta',
                    secundario: true,
                    onPressed: () => context.read<AuthProvider>().cerrarSesion(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
