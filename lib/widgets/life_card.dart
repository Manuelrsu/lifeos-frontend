import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tarjeta base de LifeOS: degradado gris sutil, borde fino y esquinas de 24.
/// Si recibe [onTap], toda la tarjeta se puede tocar.
class LifeCard extends StatelessWidget {
  const LifeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.radio = AppMedidas.radioTarjeta,
    this.gradiente = AppColors.degradadoTarjeta,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radio;
  final Gradient gradiente;

  @override
  Widget build(BuildContext context) {
    final borde = BorderRadius.circular(radio);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradiente,
        borderRadius: borde,
        border: Border.all(color: AppColors.borde),
      ),
      // Material + InkWell dan el efecto de toque sin perder el degradado
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borde,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
