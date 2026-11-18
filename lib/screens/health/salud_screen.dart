import 'package:flutter/material.dart';

import '../../widgets/avatar.dart';
import '../../widgets/estados.dart';

/// Pantalla provisional de la Fase 3: se reemplaza al construir el módulo.
class SaludScreen extends StatelessWidget {
  const SaludScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Column(
        children: [
          EncabezadoModulo(titulo: 'Salud'),
          Expanded(
            child: Center(
              child: EmptyState(
                icono: Icons.favorite_rounded,
                titulo: 'Módulo en construcción',
                mensaje: 'Este apartado se conecta al backend en la siguiente fase.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}