import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/habito.dart';
import '../../providers/habitos_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/mensajes.dart';
import '../../utils/validadores.dart';
import '../../widgets/botones.dart';

/// Crear o editar un hábito (todos los hábitos son diarios).
class HabitoFormScreen extends StatefulWidget {
  const HabitoFormScreen({super.key, this.habito});

  final Habito? habito;

  @override
  State<HabitoFormScreen> createState() => _HabitoFormScreenState();
}

class _HabitoFormScreenState extends State<HabitoFormScreen> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(text: widget.habito?.nombre);
  late final TextEditingController _descripcion = TextEditingController(text: widget.habito?.descripcion);
  bool _guardando = false;
  Map<String, String> _erroresServidor = {};

  bool get _editando => widget.habito != null;

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);
    final p = context.read<HabitosProvider>();
    try {
      if (_editando) {
        await p.actualizar(widget.habito!, nombre: _nombre.text, descripcion: _descripcion.text);
      } else {
        await p.crear(nombre: _nombre.text, descripcion: _descripcion.text.trim().isEmpty ? null : _descripcion.text);
      }
      if (!mounted) return;
      mostrarMensaje(context, _editando ? 'Hábito actualizado' : 'Hábito creado. ¡A por la racha!');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _erroresServidor = e.codigo == 409 ? {'nombre': e.mensaje} : e.errores;
      });
      if (_erroresServidor.isEmpty) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar hábito' : 'Nuevo hábito')),
      body: SafeArea(
        child: Form(
          key: _formulario,
          child: ListView(
            padding: const EdgeInsets.all(AppMedidas.margenPantalla),
            children: [
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => Validadores.texto(v, minimo: 2, maximo: 100, campo: 'El nombre'),
                forceErrorText: _erroresServidor['nombre'],
                onChanged: (_) => setState(() => _erroresServidor = {}),
                decoration: const InputDecoration(labelText: 'Nombre (ej.: Leer 20 minutos)', prefixIcon: Icon(Icons.repeat_rounded)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcion,
                maxLines: 3,
                minLines: 1,
                validator: (v) => Validadores.textoOpcional(v, maximo: 255),
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              ),
              const SizedBox(height: 12),
              Text('Los hábitos son diarios: márcalos cada día que los cumplas.', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 32),
              PillButton(texto: _editando ? 'Guardar cambios' : 'Crear hábito', cargando: _guardando, onPressed: _guardar),
            ],
          ),
        ),
      ),
    );
  }
}
