import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/salud.dart';
import '../../providers/salud_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/fechas.dart';
import '../../utils/mensajes.dart';
import '../../utils/validadores.dart';
import '../../widgets/botones.dart';
import '../../widgets/campos.dart';

/// Registrar o editar una actividad física / entrenamiento (tipo, duración, fecha y notas).
class ActividadFormScreen extends StatefulWidget {
  const ActividadFormScreen({super.key, this.actividad, this.titulo = 'Nueva actividad', this.sugerencias = const []});

  final Actividad? actividad;
  final String titulo;

  /// Tipos sugeridos para tocar y llenar el campo (el usuario puede escribir otro).
  final List<String> sugerencias;

  @override
  State<ActividadFormScreen> createState() => _ActividadFormScreenState();
}

class _ActividadFormScreenState extends State<ActividadFormScreen> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _tipo = TextEditingController(text: widget.actividad?.tipo);
  late final TextEditingController _minutos = TextEditingController(text: widget.actividad?.duracionMinutos.toString());
  late final TextEditingController _notas = TextEditingController(text: widget.actividad?.descripcion);
  late DateTime _fecha = widget.actividad?.fecha ?? Fechas.hoy();
  bool _guardando = false;
  Map<String, String> _erroresServidor = {};

  bool get _editando => widget.actividad != null;

  @override
  void dispose() {
    _tipo.dispose();
    _minutos.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await context.read<SaludProvider>().guardarActividad(
            id: widget.actividad?.id,
            tipo: _tipo.text,
            duracionMinutos: int.parse(_minutos.text.trim()),
            fecha: _fecha,
            descripcion: _notas.text,
          );
      if (!mounted) return;
      mostrarMensaje(context, _editando ? 'Actividad actualizada' : 'Actividad registrada');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _erroresServidor = e.errores;
      });
      mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  Future<void> _eliminar() async {
    final ok = await confirmar(context, titulo: '¿Eliminar actividad?', mensaje: '«${widget.actividad!.tipo}» se eliminará del historial.');
    if (!ok || !mounted) return;
    try {
      await context.read<SaludProvider>().eliminarActividad(widget.actividad!.id);
      if (!mounted) return;
      mostrarMensaje(context, 'Actividad eliminada');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar actividad' : widget.titulo),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Eliminar actividad',
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              onPressed: _eliminar,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formulario,
          child: ListView(
            padding: const EdgeInsets.all(AppMedidas.margenPantalla),
            children: [
              TextFormField(
                controller: _tipo,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => Validadores.texto(v, minimo: 2, maximo: 50, campo: 'El tipo'),
                forceErrorText: _erroresServidor['tipo'],
                decoration: const InputDecoration(labelText: 'Tipo (ej.: correr, pesas)', prefixIcon: Icon(Icons.fitness_center_rounded)),
              ),
              if (widget.sugerencias.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in widget.sugerencias)
                      ActionChip(
                        label: Text(s),
                        backgroundColor: AppColors.superficie,
                        side: const BorderSide(color: AppColors.borde),
                        shape: const StadiumBorder(),
                        onPressed: () => setState(() => _tipo.text = s),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _minutos,
                keyboardType: TextInputType.number,
                validator: (v) => Validadores.entero(v, minimo: 1, maximo: 1440),
                forceErrorText: _erroresServidor['duracion_minutos'],
                decoration: const InputDecoration(labelText: 'Duración', prefixIcon: Icon(Icons.timer_outlined), suffixText: 'min'),
              ),
              const SizedBox(height: 16),
              CampoFecha(
                etiqueta: 'Fecha',
                fecha: _fecha,
                ultima: Fechas.hoy(), // no se registran actividades futuras
                alCambiar: (f) => setState(() => _fecha = f),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notas,
                minLines: 2,
                maxLines: 4,
                validator: (v) => Validadores.textoOpcional(v, maximo: 500),
                decoration: const InputDecoration(labelText: 'Notas (opcional)', alignLabelWithHint: true),
              ),
              const SizedBox(height: 32),
              PillButton(texto: _editando ? 'Guardar cambios' : 'Registrar', degradadoSalud: true, cargando: _guardando, onPressed: _guardar),
            ],
          ),
        ),
      ),
    );
  }
}
