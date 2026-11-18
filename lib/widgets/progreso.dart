import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Anillo circular que se llena con una animación corta (ref. 04).
/// [progreso] va de 0.0 a 1.0; [centro] es lo que se muestra adentro.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progreso,
    required this.centro,
    this.tamano = 120,
    this.grosor = 10,
    this.color = AppColors.menta,
    this.gradiente,
  });

  final double progreso;
  final Widget centro;
  final double tamano;
  final double grosor;
  final Color color;
  final Gradient? gradiente;

  @override
  Widget build(BuildContext context) {
    final destino = progreso.isNaN ? 0.0 : progreso.clamp(0.0, 1.0);
    return SizedBox(
      width: tamano,
      height: tamano,
      // TweenAnimationBuilder anima de 0 al valor (y entre valores cuando cambia)
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: destino),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, valor, _) => CustomPaint(
          painter: _PintorAnillo(valor: valor, grosor: grosor, color: color, gradiente: gradiente),
          child: Center(child: centro),
        ),
      ),
    );
  }
}

class _PintorAnillo extends CustomPainter {
  _PintorAnillo({required this.valor, required this.grosor, required this.color, this.gradiente});

  final double valor;
  final double grosor;
  final Color color;
  final Gradient? gradiente;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(grosor / 2, grosor / 2, size.width - grosor, size.height - grosor);

    final fondo = Paint()
      ..color = AppColors.superficie
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor;
    canvas.drawArc(rect, 0, 2 * math.pi, false, fondo);

    if (valor <= 0) return;
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;
    if (gradiente != null) {
      trazo.shader = gradiente!.createShader(rect);
    } else {
      trazo.color = color;
    }
    // Empieza arriba (-90°) y avanza en el sentido del reloj
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * valor, false, trazo);
  }

  @override
  bool shouldRepaint(_PintorAnillo anterior) =>
      anterior.valor != valor || anterior.color != color || anterior.grosor != grosor;
}

/// Barra de progreso pequeña y redondeada (ref. 03).
class MiniProgressBar extends StatelessWidget {
  const MiniProgressBar({super.key, required this.progreso, this.color = AppColors.menta, this.ancho = 48});

  final double progreso;
  final Color color;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    final valor = progreso.isNaN ? 0.0 : progreso.clamp(0.0, 1.0);
    return SizedBox(
      width: ancho,
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppMedidas.radioPildora),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: valor),
          duration: const Duration(milliseconds: 300),
          builder: (context, v, _) => LinearProgressIndicator(
            value: v,
            backgroundColor: AppColors.superficie,
            color: color,
            minHeight: 6,
          ),
        ),
      ),
    );
  }
}
