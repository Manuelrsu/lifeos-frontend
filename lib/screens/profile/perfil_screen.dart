import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mi_dia_provider.dart';
import '../../providers/preferencias_provider.dart';
import '../../services/preferencias_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/fechas.dart';
import '../../utils/mensajes.dart';
import '../../widgets/avatar.dart';
import '../../widgets/chips.dart';
import '../../widgets/life_card.dart';
import 'cambiar_contrasena_screen.dart';
import 'editar_perfil_screen.dart';

/// Perfil: datos de la cuenta, configuración básica y cierre de sesión.
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

  Future<void> _elegirVaso(BuildContext context) async {
    final preferencias = context.read<PreferenciasProvider>();
    final elegido = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (contexto) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('¿Cuánto mide tu vaso?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            for (final ml in PreferenciasService.tamanosVaso)
              ListTile(
                leading: const Icon(Icons.local_drink_rounded),
                title: Text('$ml ml'),
                trailing: ml == preferencias.vasoMl ? const Icon(Icons.check_rounded, color: AppColors.menta) : null,
                onTap: () => Navigator.of(contexto).pop(ml),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (elegido != null) {
      await preferencias.cambiarVaso(elegido);
      if (context.mounted) mostrarMensaje(context, 'Cada vaso ahora suma $elegido ml');
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final vasoMl = context.watch<PreferenciasProvider>().vasoMl;
    final metaAgua = context.watch<MiDiaProvider>().resumen?.metaAguaMl;
    final tema = Theme.of(context).textTheme;

    if (usuario == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppMedidas.margenPantalla, 8, AppMedidas.margenPantalla, 32),
          children: [
            Center(child: AvatarIniciales(iniciales: usuario.iniciales, tamano: 88)),
            const SizedBox(height: 16),
            Text(usuario.nombre, style: tema.headlineMedium, textAlign: TextAlign.center),
            Text(usuario.correo, style: tema.bodyMedium?.copyWith(color: AppColors.textoSecundario), textAlign: TextAlign.center),
            const SizedBox(height: 28),

            const _Titulo('Cuenta'),
            LifeCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: const Text('Editar perfil'),
                    subtitle: const Text('Nombre y correo'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditarPerfilScreen())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded),
                    title: const Text('Cambiar contraseña'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CambiarContrasenaScreen())),
                  ),
                  if (usuario.fechaCreacion != null)
                    ListTile(
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: const Text('Miembro desde'),
                      subtitle: Text(Fechas.conAnio(usuario.fechaCreacion!.toLocal())),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const _Titulo('Configuración'),
            LifeCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.local_drink_rounded),
                    title: const Text('Tamaño del vaso'),
                    subtitle: const Text('Se guarda solo en este teléfono'),
                    trailing: Text('$vasoMl ml', style: const TextStyle(color: AppColors.menta, fontWeight: FontWeight.w600)),
                    onTap: () => _elegirVaso(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Meta diaria de agua'),
                    // La meta la define el servidor para todos; no se puede cambiar desde la app
                    subtitle: const Text('La define el servidor (no se puede cambiar desde la app)'),
                    trailing: Text(metaAgua == null ? '—' : '$metaAgua ml'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.bedtime_outlined),
                    title: Text('Meta de sueño'),
                    subtitle: Text('Valor fijo de la app'),
                    trailing: Text('${PreferenciasService.metaSuenoHoras} h'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const _Titulo('Acerca de'),
            const LifeCard(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(leading: Icon(Icons.info_outline_rounded), title: Text('LifeOS'), subtitle: Text('Versión 1.0.0')),
                  ListTile(
                    leading: Icon(Icons.dns_outlined),
                    title: Text('Servidor'),
                    subtitle: Text(ApiConfig.urlBase),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: TextButton.icon(
                onPressed: () => _cerrarSesion(context),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: StatusChip(texto: 'Tus datos se guardan en el servidor de LifeOS')),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
      );
}
