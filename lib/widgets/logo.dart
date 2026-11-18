import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Logo de LifeOS hecho con widgets (sin imágenes): un cuadro menta y el nombre.
class LogoLifeOS extends StatelessWidget {
  const LogoLifeOS({super.key, this.tamano = 56, this.conTexto = true});

  final double tamano;
  final bool conTexto;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tamano,
          height: tamano,
          decoration: BoxDecoration(color: AppColors.menta, borderRadius: BorderRadius.circular(tamano * 0.3)),
          child: Icon(Icons.auto_awesome_rounded, color: AppColors.sobreMenta, size: tamano * 0.55),
        ),
        if (conTexto) ...[
          const SizedBox(height: 12),
          Text('LifeOS', style: Theme.of(context).textTheme.headlineMedium),
        ],
      ],
    );
  }
}
