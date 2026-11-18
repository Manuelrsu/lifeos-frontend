import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/materia.dart';
import '../../providers/smartstudy_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/mensajes.dart';
import '../../utils/validadores.dart';
import '../../widgets/botones.dart';
import '../../widgets/campos.dart';
import '../../widgets/chips.dart';

/// Crear o editar una materia (nombre, docente y color).
/// Eliminar una materia borra también sus tareas y evaluaciones (se pide confirmación).
class MateriaFormScreen extends StatefulWidget {
  const MateriaFormScreen({super.key, this.materia});

  final Materia? materia;

  @override
  State<MateriaFormScreen> createState() => _MateriaFormScreenState();
}

class _MateriaFormScreenState extends State<MateriaFormScreen> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(text: widget.materia?.nombre);
  late final TextEditingController _docente = TextEditingController(text: widget.materia?.docente);
  late int _color;
  bool _guardando = false;
  Map<String, String> _erroresServidor = {};

  bool get _editando => widget.materia != null;

  @override
  void initState() {
    super.initState();
    final p = context.read<SmartStudyProvider>();
    // Materia nueva: se propone el siguiente color de la paleta
    _color = widget.materia != null ? p.colorDe(widget.materia!.id) : p.materias.length % AppColors.paletaMaterias.length;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _docente.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await context.read<SmartStudyProvider>().guardarMateria(
            id: widget.materia?.id,
            nombre: _nombre.text,
            docente: _docente.text,
            color: _color,
          );
      if (!mounted) return;
      mostrarMensaje(context, _editando ? 'Materia actualizada' : 'Materia creada');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        // 409: ya existe una materia con ese nombre
        _erroresServidor = e.codigo == 409 ? {'nombre': e.mensaje} : e.errores;
      });
      if (_erroresServidor.isEmpty) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  Future<void> _eliminar() async {
    final p = context.read<SmartStudyProvider>();
    final id = widget.materia!.id;
    final tareas = p.tareas.where((t) => t.materiaId == id).length;
    final evaluaciones = p.evaluaciones.where((e) => e.materiaId == id).length;
    final ok = await confirmar(
      context,
      titulo: '¿Eliminar «${widget.materia!.nombre}»?',
      mensaje: 'También se eliminarán sus $tareas tarea(s) y $evaluaciones evaluación(es). Esta acción no se puede deshacer.',
    );
    if (!ok || !mounted) return;
    try {
      await p.eliminarMateria(id);
      if (!mounted) return;
      mostrarMensaje(context, 'Materia eliminada');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar materia' : 'Nueva materia'),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Eliminar materia',
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
              Center(child: IconoMateria(color: AppColors.paletaMaterias[_color], tamano: 64)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => Validadores.texto(v, minimo: 2, maximo: 100, campo: 'El nombre'),
                forceErrorText: _erroresServidor['nombre'],
                onChanged: (_) => setState(() => _erroresServidor = {}),
                decoration: const InputDecoration(labelText: 'Nombre de la materia', prefixIcon: Icon(Icons.school_rounded)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _docente,
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validadores.textoOpcional(v, maximo: 100),
                decoration: const InputDecoration(labelText: 'Docente (opcional)', prefixIcon: Icon(Icons.person_outline_rounded)),
              ),
              const SizedBox(height: 24),
              Text('Color', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              SelectorColor(seleccionado: _color, alCambiar: (i) => setState(() => _color = i)),
              const SizedBox(height: 8),
              const StatusChip(texto: 'El color se guarda solo en este teléfono'),
              const SizedBox(height: 32),
              PillButton(texto: _editando ? 'Guardar cambios' : 'Crear materia', cargando: _guardando, onPressed: _guardar),
            ],
          ),
        ),
      ),
    );
  }
}
