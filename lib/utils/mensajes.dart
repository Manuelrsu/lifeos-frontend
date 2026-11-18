import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Muestra un mensaje corto abajo de la pantalla (confirmaciones y errores).
void mostrarMensaje(BuildContext context, String texto, {bool error = false}) {
  final mensajero = ScaffoldMessenger.of(context);
  mensajero.hideCurrentSnackBar();
  mensajero.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: error ? AppColors.error : AppColors.menta,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    ),
  );
}

/// Diálogo de confirmación (por ejemplo, antes de eliminar). Devuelve true si se confirma.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String textoConfirmar = 'Eliminar',
  bool peligroso = true,
}) async {
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(contexto).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.textoSecundario),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(contexto).pop(true),
          style: peligroso ? TextButton.styleFrom(foregroundColor: AppColors.error) : null,
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
  return respuesta ?? false;
}
