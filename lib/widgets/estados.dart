import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'botones.dart';

/// Estado vacío: icono, texto y (si hay) una acción para empezar.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.textoAccion,
    this.onAccion,
  });

  final IconData icono;
  final String titulo;
  final String? mensaje;
  final String? textoAccion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.superficie, borderRadius: BorderRadius.circular(20)),
            child: Icon(icono, size: 30, color: AppColors.menta),
          ),
          const SizedBox(height: 16),
          Text(titulo, style: tema.titleMedium, textAlign: TextAlign.center),
          if (mensaje != null) ...[
            const SizedBox(height: 6),
            Text(mensaje!, style: tema.bodyMedium?.copyWith(color: AppColors.textoSecundario), textAlign: TextAlign.center),
          ],
          if (textoAccion != null && onAccion != null) ...[
            const SizedBox(height: 20),
            PillButton(texto: textoAccion!, onPressed: onAccion, icono: Icons.add_rounded, expandido: false),
          ],
        ],
      ),
    );
  }
}

/// Estado de error: mensaje amable (nunca trazas técnicas) y botón Reintentar.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.suave(AppColors.error), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.cloud_off_rounded, size: 30, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          Text(mensaje, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          PillButton(texto: 'Reintentar', onPressed: onReintentar, icono: Icons.refresh_rounded, expandido: false),
        ],
      ),
    );
  }
}

/// Indicador de carga centrado, con un texto opcional.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.mensaje});

  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (mensaje != null) ...[
              const SizedBox(height: 16),
              Text(mensaje!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
