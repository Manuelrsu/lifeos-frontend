import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botón circular de 44 px con borde fino (ref. 01). Siempre lleva una acción
/// y un [tooltip] para que se entienda qué hace.
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icono,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icono;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.superficie,
        shape: const CircleBorder(side: BorderSide(color: AppColors.borde)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: AppMedidas.botonIcono,
            height: AppMedidas.botonIcono,
            child: Icon(icono, size: 22, color: AppColors.texto),
          ),
        ),
      ),
    );
  }
}

/// Botón en forma de píldora.
/// - principal: fondo menta (o el degradado de Salud si [degradadoSalud]).
/// - secundario: solo texto.
/// Con [cargando] se desactiva y muestra un indicador.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icono,
    this.cargando = false,
    this.secundario = false,
    this.degradadoSalud = false,
    this.expandido = true,
  });

  final String texto;
  final VoidCallback? onPressed;
  final IconData? icono;
  final bool cargando;
  final bool secundario;
  final bool degradadoSalud;
  final bool expandido;

  @override
  Widget build(BuildContext context) {
    final accion = cargando ? null : onPressed;

    if (secundario) {
      return TextButton.icon(
        onPressed: accion,
        icon: icono != null ? Icon(icono, size: 18) : const SizedBox.shrink(),
        label: Text(texto),
      );
    }

    final contenido = cargando
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.sobreMenta),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icono != null) ...[Icon(icono, size: 20), const SizedBox(width: 8)],
              Flexible(child: Text(texto, overflow: TextOverflow.ellipsis)),
            ],
          );

    Widget boton;
    if (degradadoSalud) {
      // Botón con el degradado turquesa (solo en Salud)
      boton = Opacity(
        opacity: accion == null && !cargando ? 0.5 : 1,
        child: DecoratedBox(
          decoration: const ShapeDecoration(shape: StadiumBorder(), gradient: AppColors.degradadoSalud),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: accion,
              child: SizedBox(
                height: 52,
                child: Center(
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(color: AppColors.texto, fontWeight: FontWeight.w600, fontSize: 15),
                    child: IconTheme.merge(data: const IconThemeData(color: AppColors.texto), child: contenido),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      boton = FilledButton(onPressed: accion, child: contenido);
    }

    return expandido ? SizedBox(width: double.infinity, child: boton) : boton;
  }
}
