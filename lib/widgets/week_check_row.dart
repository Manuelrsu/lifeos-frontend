import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fila de 7 cuadros (L M M J V S D) con ✓ en los días cumplidos (ref. 03).
///
/// [cumplidos] tiene 7 valores, de lunes a domingo.
/// [habilitados] indica qué días se pueden tocar (por ejemplo, no los futuros).
/// [onTocarDia] recibe el índice del día (0 = lunes).
class WeekCheckRow extends StatelessWidget {
  const WeekCheckRow({
    super.key,
    required this.cumplidos,
    required this.habilitados,
    this.indiceHoy,
    this.onTocarDia,
    this.cargando = const [false, false, false, false, false, false, false],
  });

  static const List<String> iniciales = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const List<String> nombres = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

  final List<bool> cumplidos;
  final List<bool> habilitados;
  final int? indiceHoy;
  final ValueChanged<int>? onTocarDia;
  final List<bool> cargando;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        final hecho = cumplidos[i];
        final activo = habilitados[i] && onTocarDia != null && !cargando[i];
        final esHoy = indiceHoy == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 6 ? 4 : 0),
            child: Semantics(
              button: activo,
              label: '${nombres[i]}${esHoy ? ' (hoy)' : ''}: ${hecho ? 'cumplido' : 'sin cumplir'}',
              child: Material(
                color: hecho ? AppColors.menta : AppColors.superficie,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: activo ? () => onTocarDia!(i) : null,
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: esHoy && !hecho ? Border.all(color: AppColors.menta, width: 1.5) : null,
                    ),
                    child: cargando[i]
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        // AnimatedSwitcher: el ✓ aparece con una transición corta
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (hijo, animacion) => ScaleTransition(scale: animacion, child: hijo),
                            child: hecho
                                ? const Icon(Icons.check_rounded, key: ValueKey('si'), size: 20, color: AppColors.sobreMenta)
                                : Text(
                                    iniciales[i],
                                    key: const ValueKey('no'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: habilitados[i] ? AppColors.texto : AppColors.textoSecundario.withValues(alpha: 0.5),
                                    ),
                                  ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
