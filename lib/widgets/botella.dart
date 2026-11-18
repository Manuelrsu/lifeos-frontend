import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botella que se llena según el porcentaje de la meta de agua (ref. 04).
/// El llenado se anima cuando cambia el valor.
class BotellaAgua extends StatelessWidget {
  const BotellaAgua({super.key, required this.progreso, this.ancho = 120, this.alto = 220});

  /// 0.0 a 1.0 (si pasa de la meta se dibuja llena).
  final double progreso;
  final double ancho;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final destino = progreso.isNaN ? 0.0 : progreso.clamp(0.0, 1.0);
    return Semantics(
      label: 'Botella de agua al ${(destino * 100).round()} %',
      child: SizedBox(
        width: ancho,
        height: alto,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: destino),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, valor, _) => CustomPaint(painter: _PintorBotella(valor)),
        ),
      ),
    );
  }
}

class _PintorBotella extends CustomPainter {
  _PintorBotella(this.valor);

  final double valor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Forma: cuello angosto arriba y cuerpo redondeado
    final cuelloAncho = w * 0.38;
    final cuelloAlto = h * 0.14;
    final hombro = h * 0.26;
    final forma = Path()
      ..moveTo((w - cuelloAncho) / 2, 0)
      ..lineTo((w + cuelloAncho) / 2, 0)
      ..lineTo((w + cuelloAncho) / 2, cuelloAlto)
      ..quadraticBezierTo(w, cuelloAlto + 4, w, hombro)
      ..lineTo(w, h - 24)
      ..quadraticBezierTo(w, h, w - 24, h)
      ..lineTo(24, h)
      ..quadraticBezierTo(0, h, 0, h - 24)
      ..lineTo(0, hombro)
      ..quadraticBezierTo(0, cuelloAlto + 4, (w - cuelloAncho) / 2, cuelloAlto)
      ..close();

    // Fondo de la botella
    canvas.drawPath(forma, Paint()..color = AppColors.superficie);

    // Agua: un rectángulo recortado con la forma de la botella
    if (valor > 0) {
      final nivel = h * (1 - valor);
      canvas.save();
      canvas.clipPath(forma);
      final agua = Rect.fromLTWH(0, nivel, w, h - nivel);
      canvas.drawRect(
        agua,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.saludClaro, AppColors.saludOscuro],
          ).createShader(agua),
      );
      canvas.restore();
    }

    // Borde
    canvas.drawPath(
      forma,
      Paint()
        ..color = AppColors.saludClaro.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_PintorBotella anterior) => anterior.valor != valor;
}
