import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/fechas.dart';

/// Campo de fecha: al tocarlo abre el calendario (showDatePicker) con el tema oscuro.
class CampoFecha extends StatelessWidget {
  const CampoFecha({
    super.key,
    required this.etiqueta,
    required this.fecha,
    required this.alCambiar,
    this.primera,
    this.ultima,
    this.icono = Icons.event_rounded,
  });

  final String etiqueta;
  final DateTime fecha;
  final ValueChanged<DateTime> alCambiar;

  /// Límites del calendario (por ejemplo, Salud no permite fechas futuras).
  final DateTime? primera;
  final DateTime? ultima;
  final IconData icono;

  Future<void> _elegir(BuildContext context) async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: primera ?? DateTime(2020),
      lastDate: ultima ?? DateTime(2035, 12, 31),
      helpText: etiqueta,
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (elegida != null) alCambiar(Fechas.soloDia(elegida));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppMedidas.radioItem),
      onTap: () => _elegir(context),
      child: InputDecorator(
        decoration: InputDecoration(labelText: etiqueta, prefixIcon: Icon(icono)),
        child: Text('${Fechas.largo(fecha)} ${fecha.year}'),
      ),
    );
  }
}

/// Selector de color con la paleta fija de materias (6 círculos).
class SelectorColor extends StatelessWidget {
  const SelectorColor({super.key, required this.seleccionado, required this.alCambiar});

  final int seleccionado;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(AppColors.paletaMaterias.length, (i) {
        final color = AppColors.paletaMaterias[i];
        final activo = i == seleccionado;
        return Semantics(
          button: true,
          selected: activo,
          label: 'Color ${AppColors.nombresPaleta[i]}',
          child: GestureDetector(
            onTap: () => alCambiar(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: activo ? AppColors.texto : Colors.transparent, width: 3),
              ),
              child: activo ? const Icon(Icons.check_rounded, color: AppColors.sobreMenta) : null,
            ),
          ),
        );
      }),
    );
  }
}

/// Icono cuadrado con el color suave de la materia (ref. 02).
class IconoMateria extends StatelessWidget {
  const IconoMateria({super.key, required this.color, this.icono = Icons.menu_book_rounded, this.tamano = 40});

  final Color color;
  final IconData icono;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(color: AppColors.suave(color), borderRadius: BorderRadius.circular(tamano * 0.3)),
      child: Icon(icono, size: tamano * 0.5, color: color),
    );
  }
}
