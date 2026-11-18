import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/evaluacion.dart';
import '../../providers/smartstudy_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/fechas.dart';
import '../../utils/mensajes.dart';
import '../../utils/validadores.dart';
import '../../widgets/botones.dart';
import '../../widgets/campos.dart';

/// Crear o editar una evaluación (parcial, quiz, exposición...).
class EvaluacionFormScreen extends StatefulWidget {
  const EvaluacionFormScreen({super.key, this.evaluacion});

  final Evaluacion? evaluacion;

  @override
  State<EvaluacionFormScreen> createState() => _EvaluacionFormScreenState();
}

class _EvaluacionFormScreenState extends State<EvaluacionFormScreen> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(text: widget.evaluacion?.nombre);
  late final TextEditingController _descripcion = TextEditingController(text: widget.evaluacion?.descripcion);
  late DateTime _fecha = widget.evaluacion?.fecha ?? Fechas.hoy().add(const Duration(days: 7));
  int? _materiaId;
  bool _guardando = false;
  Map<String, String> _erroresServidor = {};

  bool get _editando => widget.evaluacion != null;

  @override
  void initState() {
    super.initState();
    final materias = context.read<SmartStudyProvider>().materias;
    _materiaId = widget.evaluacion?.materiaId ?? (materias.isNotEmpty ? materias.first.id : null);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await context.read<SmartStudyProvider>().guardarEvaluacion(Evaluacion(
            id: widget.evaluacion?.id ?? 0,
            materiaId: _materiaId!,
            nombre: _nombre.text.trim(),
            fecha: _fecha,
            descripcion: _descripcion.text.trim(),
          ));
      if (!mounted) return;
      mostrarMensaje(context, _editando ? 'Evaluación actualizada' : 'Evaluación creada');
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
    final ok = await confirmar(context, titulo: '¿Eliminar evaluación?', mensaje: '«${widget.evaluacion!.nombre}» se eliminará.');
    if (!ok || !mounted) return;
    try {
      await context.read<SmartStudyProvider>().eliminarEvaluacion(widget.evaluacion!.id);
      if (!mounted) return;
      mostrarMensaje(context, 'Evaluación eliminada');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SmartStudyProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar evaluación' : 'Nueva evaluación'),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Eliminar evaluación',
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
                controller: _nombre,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => Validadores.texto(v, minimo: 2, maximo: 150, campo: 'El nombre'),
                forceErrorText: _erroresServidor['nombre'],
                decoration: const InputDecoration(labelText: 'Nombre (ej.: Parcial 1)', prefixIcon: Icon(Icons.assignment_rounded)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _materiaId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Materia', prefixIcon: Icon(Icons.school_rounded)),
                dropdownColor: AppColors.superficie,
                items: [for (final m in p.materias) DropdownMenuItem(value: m.id, child: Text(m.nombre, overflow: TextOverflow.ellipsis))],
                validator: (v) => v == null ? 'Elige una materia' : null,
                onChanged: (v) => setState(() => _materiaId = v),
              ),
              const SizedBox(height: 16),
              CampoFecha(etiqueta: 'Fecha', fecha: _fecha, alCambiar: (f) => setState(() => _fecha = f)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcion,
                minLines: 2,
                maxLines: 4,
                validator: (v) => Validadores.textoOpcional(v, maximo: 2000),
                decoration: const InputDecoration(labelText: 'Temas o notas (opcional)', alignLabelWithHint: true),
              ),
              const SizedBox(height: 32),
              PillButton(texto: _editando ? 'Guardar cambios' : 'Crear evaluación', cargando: _guardando, onPressed: _guardar),
            ],
          ),
        ),
      ),
    );
  }
}
