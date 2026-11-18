import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/chips.dart';
import '../../widgets/life_card.dart';
import '../../widgets/progreso.dart';
import 'login_screen.dart';
import 'registro_screen.dart';

/// Pantalla de bienvenida (ref. 01, izquierda): tarjetas apiladas como ilustración,
/// el lema, el botón circular para iniciar sesión y el enlace para crear una cuenta.
class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({super.key});

  void _irALogin(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));

  void _irARegistro(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegistroScreen()));

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, limites) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: limites.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppMedidas.margenPantalla, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _IlustracionTarjetas(),
                    const SizedBox(height: 32),
                    Column(
                      children: [
                        Text(
                          'Todo tu progreso en una sola aplicación',
                          style: tema.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Organiza tus materias y tareas, cumple tus hábitos y lleva tu agua, sueño y entrenamiento en un solo lugar.',
                          style: tema.bodyMedium?.copyWith(color: AppColors.textoSecundario),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        _BotonAnillo(onPressed: () => _irALogin(context)),
                        const SizedBox(height: 8),
                        Text('Iniciar sesión', style: tema.bodySmall),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('¿Primera vez aquí?', style: tema.bodyMedium?.copyWith(color: AppColors.textoSecundario)),
                            TextButton(onPressed: () => _irARegistro(context), child: const Text('Crear cuenta')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón circular menta con un anillo alrededor y una flecha (ref. 01).
class _BotonAnillo extends StatelessWidget {
  const _BotonAnillo({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Iniciar sesión',
      child: SizedBox(
        width: 92,
        height: 92,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // El anillo es decorativo: un ProgressRing al 75 %, como en la referencia
            const ProgressRing(progreso: 0.75, centro: SizedBox.shrink(), tamano: 92, grosor: 3),
            Material(
              color: AppColors.menta,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onPressed,
                child: const SizedBox(
                  width: 70,
                  height: 70,
                  child: Icon(Icons.arrow_forward_rounded, color: AppColors.sobreMenta, size: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ilustración hecha con widgets: tres tarjetas inclinadas con contenido de EJEMPLO.
/// ILUSTRACIÓN: no son datos del usuario ni se guardan en ningún lado (lo indica el chip «Ejemplo»).
class _IlustracionTarjetas extends StatelessWidget {
  const _IlustracionTarjetas();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Círculo de fondo, como en la referencia
          Positioned(
            top: 0,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(color: AppColors.superficie, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            top: 10,
            left: 0,
            child: Transform.rotate(
              angle: -8 * math.pi / 180,
              child: const _TarjetaEjemplo(
                icono: Icons.water_drop_rounded,
                titulo: 'Hidratación',
                detalle: '6 de 8 vasos',
                progreso: 0.75,
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 0,
            child: Transform.rotate(
              angle: 6 * math.pi / 180,
              child: const _TarjetaEjemplo(
                icono: Icons.local_fire_department_rounded,
                titulo: 'Leer 20 minutos',
                detalle: 'Racha de 5 días',
                progreso: 0.6,
              ),
            ),
          ),
          Positioned(
            top: 128,
            child: Transform.rotate(
              angle: -2 * math.pi / 180,
              child: const _TarjetaEjemplo(
                icono: Icons.school_rounded,
                titulo: 'Taller de bases de datos',
                detalle: 'Entrega: viernes',
                progreso: 0.7,
                ancha: true,
              ),
            ),
          ),
          const Positioned(bottom: 0, right: 8, child: StatusChip(texto: 'Ejemplo')),
        ],
      ),
    );
  }
}

class _TarjetaEjemplo extends StatelessWidget {
  const _TarjetaEjemplo({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.progreso,
    this.ancha = false,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final double progreso;
  final bool ancha;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancha ? 240 : 180,
      child: LifeCard(
        padding: const EdgeInsets.all(14),
        radio: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.superficie, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icono, size: 16, color: AppColors.menta),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(detalle, style: const TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
            const SizedBox(height: 8),
            MiniProgressBar(progreso: progreso, ancho: double.infinity),
          ],
        ),
      ),
    );
  }
}
