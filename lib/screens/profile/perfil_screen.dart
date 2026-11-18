import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/mensajes.dart';
import '../../widgets/avatar.dart';
import '../../widgets/botones.dart';
import '../../widgets/life_card.dart';

/// Perfil del usuario (versión de la Fase 3: datos y cerrar sesión).
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    final ok = await confirmar(
      context,
      titulo: '¿Cerrar sesión?',
      mensaje: 'Tendrás que volver a ingresar tu correo y contraseña.',
      textoConfirmar: 'Cerrar sesión',
    );
    if (ok && context.mounted) await context.read<AuthProvider>().cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final tema = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: usuario == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(AppMedidas.margenPantalla),
              children: [
                Center(child: AvatarIniciales(iniciales: usuario.iniciales, tamano: 88)),
                const SizedBox(height: 16),
                Text(usuario.nombre, style: tema.headlineMedium, textAlign: TextAlign.center),
                Text(usuario.correo, style: tema.bodyMedium?.copyWith(color: AppColors.textoSecundario), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                LifeCard(
                  child: PillButton(
                    texto: 'Cerrar sesión',
                    icono: Icons.logout_rounded,
                    secundario: true,
                    onPressed: () => _cerrarSesion(context),
                  ),
                ),
              ],
            ),
    );
  }
}
