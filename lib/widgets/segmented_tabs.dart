import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pestañas en forma de píldora (ref. 04). La seleccionada se resalta.
/// Si [degradadoSalud] es true, la pestaña activa usa el turquesa de Salud.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.opciones,
    required this.seleccionada,
    required this.onCambio,
    this.degradadoSalud = false,
  });

  final List<String> opciones;
  final int seleccionada;
  final ValueChanged<int> onCambio;
  final bool degradadoSalud;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppMedidas.radioPildora),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        children: List.generate(opciones.length, (i) {
          final activa = i == seleccionada;
          return Expanded(
            child: Semantics(
              selected: activa,
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onCambio(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppMedidas.radioPildora),
                    color: activa && !degradadoSalud ? AppColors.tarjetaClara : null,
                    gradient: activa && degradadoSalud ? AppColors.degradadoSalud : null,
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      opciones[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: activa ? FontWeight.w600 : FontWeight.w400,
                        color: activa ? AppColors.texto : AppColors.textoSecundario,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
