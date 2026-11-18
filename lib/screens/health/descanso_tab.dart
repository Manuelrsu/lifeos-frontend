import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/salud.dart';
import '../../providers/salud_provider.dart';
import '../../services/api_service.dart';
import '../../services/preferencias_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/fechas.dart';
import '../../utils/mensajes.dart';
import '../../utils/validadores.dart';
import '../../widgets/botones.dart';
import '../../widgets/campos.dart';
import '../../widgets/life_card.dart';
import '../../widgets/progreso.dart';
import 'salud_screen.dart';

/// Descanso: anillo con las horas de anoche frente a la meta, registro e historial.
/// Solo cifras y progreso hacia la meta: sin evaluaciones tipo «Bueno» o «Malo».
class DescansoTab extends StatelessWidget {
  const DescansoTab({super.key});

  static const double meta = PreferenciasService.metaSuenoHoras;

  Future<void> _registrar(BuildContext context, {RegistroSueno? existente}) async {
    final guardado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioSueno(existente: existente),
    );
    if (guardado == true && context.mounted) mostrarMensaje(context, 'Sueño registrado');
  }

  Future<void> _eliminar(BuildContext context, RegistroSueno registro) async {
    final ok = await confirmar(context, titulo: '¿Eliminar registro?', mensaje: 'Se borrará el sueño del ${Fechas.conAnio(registro.fecha)}.');
    if (!ok || !context.mounted) return;
    try {
      await context.read<SaludProvider>().eliminarSueno(registro.fecha);
      if (context.mounted) mostrarMensaje(context, 'Registro eliminado');
    } on ApiException catch (e) {
      if (context.mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SaludProvider>();
    final tema = Theme.of(context).textTheme;
    final hoy = p.suenoDe(Fechas.hoy());
    final promedio = p.estadisticas?.promedioHoras;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LifeCard(
          child: Column(
            children: [
              Text('Sueño de anoche', style: tema.bodySmall),
              const SizedBox(height: 12),
              ProgressRing(
                progreso: hoy == null ? 0 : hoy.horas / meta,
                tamano: 168,
                grosor: 14,
                gradiente: AppColors.degradadoSalud,
                centro: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(hoy == null ? '—' : formatoHoras(hoy.horas), style: tema.titleLarge),
                    Text(
                      hoy == null ? 'sin registro' : 'meta ${meta.toStringAsFixed(0)} h · ${(hoy.horas / meta * 100).round()} %',
                      style: tema.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                promedio == null
                    ? 'Aún no hay registros esta semana'
                    : 'Promedio de 7 días: ${formatoHoras(promedio)} (${p.estadisticas!.diasConSueno} día(s) con registro)',
                style: tema.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PillButton(
          texto: hoy == null ? 'Registrar sueño' : 'Editar sueño de anoche',
          icono: Icons.bedtime_rounded,
          degradadoSalud: true,
          onPressed: () => _registrar(context, existente: hoy),
        ),
        const SizedBox(height: 20),
        Text('Últimos ${SaludProvider.diasSueno} días', style: tema.titleMedium),
        const SizedBox(height: 8),
        if (p.suenos.isEmpty)
          Text('Todavía no registras horas de sueño.', style: tema.bodySmall)
        else
          LifeCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final registro in p.suenos)
                  ListTile(
                    leading: const Icon(Icons.nights_stay_rounded, color: AppColors.saludClaro),
                    title: Text(formatoHoras(registro.horas)),
                    subtitle: Text(Fechas.relativo(registro.fecha)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${(registro.horas / meta * 100).round()} %', style: tema.bodySmall),
                        IconButton(
                          tooltip: 'Eliminar registro',
                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                          onPressed: () => _eliminar(context, registro),
                        ),
                      ],
                    ),
                    onTap: () => _registrar(context, existente: registro),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text('La fecha es la del día en que despertaste. Meta de ${meta.toStringAsFixed(0)} h (valor fijo de la app).', style: tema.bodySmall),
      ],
    );
  }
}

/// Hoja inferior para registrar o editar las horas de sueño de una fecha.
class _FormularioSueno extends StatefulWidget {
  const _FormularioSueno({this.existente});

  final RegistroSueno? existente;

  @override
  State<_FormularioSueno> createState() => _FormularioSuenoState();
}

class _FormularioSuenoState extends State<_FormularioSueno> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _horas = TextEditingController(
    text: widget.existente == null ? '' : widget.existente!.horas.toString().replaceAll(RegExp(r'\.0$'), ''),
  );
  late DateTime _fecha = widget.existente?.fecha ?? Fechas.hoy();
  bool _guardando = false;
  String? _errorServidor;

  @override
  void dispose() {
    _horas.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final horas = double.parse(_horas.text.trim().replaceAll(',', '.'));
      await context.read<SaludProvider>().guardarSueno(_fecha, horas);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _errorServidor = e.errores['horas'] ?? e.errores['fecha'] ?? e.mensaje;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // viewInsets: deja espacio para el teclado
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppMedidas.margenPantalla, 0, AppMedidas.margenPantalla, 20),
          child: Form(
            key: _formulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('¿Cuántas horas dormiste?', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _horas,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: Validadores.horasSueno,
                  forceErrorText: _errorServidor,
                  decoration: const InputDecoration(labelText: 'Horas (ej.: 7,5)', prefixIcon: Icon(Icons.bedtime_rounded), suffixText: 'h'),
                ),
                const SizedBox(height: 16),
                CampoFecha(
                  etiqueta: 'Día en que despertaste',
                  fecha: _fecha,
                  ultima: Fechas.hoy(), // el backend no acepta fechas futuras
                  alCambiar: (f) => setState(() => _fecha = f),
                ),
                const SizedBox(height: 24),
                PillButton(texto: 'Guardar', degradadoSalud: true, cargando: _guardando, onPressed: _guardar),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
