import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tarea.dart';
import '../../providers/smartstudy_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/fechas.dart';
import '../../utils/mensajes.dart';
import '../../utils/validadores.dart';
import '../../widgets/botones.dart';
import '../../widgets/campos.dart';
import '../../widgets/segmented_tabs.dart';

/// Crear o editar una tarea (POST /tareas o PUT /tareas/id). Editando, también permite eliminarla.
class TareaFormScreen extends StatefulWidget {
  const TareaFormScreen({super.key, this.tarea});

  /// null = tarea nueva.
  final Tarea? tarea;

  @override
  State<TareaFormScreen> createState() => _TareaFormScreenState();
}

class _TareaFormScreenState extends State<TareaFormScreen> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _titulo = TextEditingController(text: widget.tarea?.titulo);
  late final TextEditingController _descripcion = TextEditingController(text: widget.tarea?.descripcion);
  late DateTime _fecha = widget.tarea?.fechaEntrega ?? Fechas.hoy().add(const Duration(days: 1));
  late String _prioridad = widget.tarea?.prioridad ?? 'media';
  int? _materiaId;
  bool _guardando = false;
  Map<String, String> _erroresServidor = {};

  bool get _editando => widget.tarea != null;

  @override
  void initState() {
    super.initState();
    final materias = context.read<SmartStudyProvider>().materias;
    _materiaId = widget.tarea?.materiaId ?? (materias.isNotEmpty ? materias.first.id : null);
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);
    final tarea = Tarea(
      id: widget.tarea?.id ?? 0,
      materiaId: _materiaId!,
      titulo: _titulo.text.trim(),
      descripcion: _descripcion.text.trim(),
      fechaEntrega: _fecha,
      prioridad: _prioridad,
      estado: widget.tarea?.estado ?? 'pendiente',
    );
    try {
      await context.read<SmartStudyProvider>().guardarTarea(tarea);
      if (!mounted) return;
      mostrarMensaje(context, _editando ? 'Tarea actualizada' : 'Tarea creada');
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
    final ok = await confirmar(context, titulo: '¿Eliminar tarea?', mensaje: '«${widget.tarea!.titulo}» se eliminará definitivamente.');
    if (!ok || !mounted) return;
    try {
      await context.read<SmartStudyProvider>().eliminarTarea(widget.tarea!.id);
      if (!mounted) return;
      mostrarMensaje(context, 'Tarea eliminada');
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
        title: Text(_editando ? 'Editar tarea' : 'Nueva tarea'),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Eliminar tarea',
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
                controller: _titulo,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => Validadores.texto(v, minimo: 2, maximo: 150, campo: 'El título'),
                forceErrorText: _erroresServidor['titulo'],
                decoration: const InputDecoration(labelText: 'Título', prefixIcon: Icon(Icons.title_rounded)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcion,
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => Validadores.textoOpcional(v, maximo: 2000),
                decoration: const InputDecoration(labelText: 'Descripción (opcional)', alignLabelWithHint: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _materiaId,
                isExpanded: true, // ocupa el ancho del campo (los nombres largos se cortan con «…»)
                decoration: const InputDecoration(labelText: 'Materia', prefixIcon: Icon(Icons.school_rounded)),
                dropdownColor: AppColors.superficie,
                borderRadius: BorderRadius.circular(AppMedidas.radioItem),
                items: [
                  for (final m in p.materias)
                    DropdownMenuItem(
                      value: m.id,
                      child: Row(
                        children: [
                          CircleAvatar(radius: 6, backgroundColor: AppColors.paletaMaterias[p.colorDe(m.id)]),
                          const SizedBox(width: 10),
                          Flexible(child: Text(m.nombre, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                ],
                validator: (v) => v == null ? 'Elige una materia' : null,
                onChanged: (v) => setState(() => _materiaId = v),
              ),
              const SizedBox(height: 16),
              CampoFecha(
                etiqueta: 'Fecha de entrega',
                fecha: _fecha,
                alCambiar: (f) => setState(() => _fecha = f),
              ),
              if (_erroresServidor['fecha_entrega'] != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 6),
                  child: Text(_erroresServidor['fecha_entrega']!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              const SizedBox(height: 20),
              Text('Prioridad', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              SegmentedTabs(
                opciones: const ['Baja', 'Media', 'Alta'],
                seleccionada: Tarea.prioridades.indexOf(_prioridad),
                onCambio: (i) => setState(() => _prioridad = Tarea.prioridades[i]),
              ),
              const SizedBox(height: 32),
              PillButton(texto: _editando ? 'Guardar cambios' : 'Crear tarea', cargando: _guardando, onPressed: _guardar),
            ],
          ),
        ),
      ),
    );
  }
}
