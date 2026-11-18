import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/profile/perfil_screen.dart';
import '../theme/app_theme.dart';

/// Abre la pantalla de Perfil (desde el avatar de cualquier módulo).
void abrirPerfil(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PerfilScreen()));
}

/// Círculo con las iniciales del usuario.
class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales({super.key, required this.iniciales, this.tamano = 36});

  final String iniciales;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.menta, shape: BoxShape.circle),
      child: Text(
        iniciales,
        style: TextStyle(color: AppColors.sobreMenta, fontWeight: FontWeight.w700, fontSize: tamano * 0.38),
      ),
    );
  }
}

/// Chip de saludo de Mi Día: avatar + «Hola de nuevo, Nombre». Al tocarlo abre el Perfil.
class SaludoChip extends StatelessWidget {
  const SaludoChip({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    return Semantics(
      button: true,
      label: 'Abrir perfil',
      child: Material(
        color: AppColors.superficie,
        shape: const StadiumBorder(side: BorderSide(color: AppColors.borde)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => abrirPerfil(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AvatarIniciales(iniciales: usuario?.iniciales ?? '?'),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Hola de nuevo,', style: TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
                      Text(
                        usuario?.primerNombre ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de avatar (solo el círculo) para la barra superior de los módulos.
class AvatarBoton extends StatelessWidget {
  const AvatarBoton({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    return Tooltip(
      message: 'Perfil',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => abrirPerfil(context),
        child: AvatarIniciales(iniciales: usuario?.iniciales ?? '?', tamano: AppMedidas.botonIcono),
      ),
    );
  }
}

/// Encabezado común de los módulos: título grande, acciones y avatar.
class EncabezadoModulo extends StatelessWidget {
  const EncabezadoModulo({super.key, required this.titulo, this.acciones = const []});

  final String titulo;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppMedidas.margenPantalla, 12, AppMedidas.margenPantalla, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: Theme.of(context).textTheme.headlineLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          for (final accion in acciones) ...[accion, const SizedBox(width: 8)],
          const AvatarBoton(),
        ],
      ),
    );
  }
}
