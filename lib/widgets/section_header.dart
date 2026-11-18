import 'package:flutter/material.dart';

/// Título de sección con un «Ver todo» opcional a la derecha.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.titulo, this.onVerTodo, this.textoAccion = 'Ver todo'});

  final String titulo;
  final VoidCallback? onVerTodo;
  final String textoAccion;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(titulo, style: Theme.of(context).textTheme.titleMedium)),
        // Solo se muestra el botón si hay una acción real
        if (onVerTodo != null) TextButton(onPressed: onVerTodo, child: Text(textoAccion)),
      ],
    );
  }
}
