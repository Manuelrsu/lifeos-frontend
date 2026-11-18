import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/mensajes.dart';
import '../../utils/validadores.dart';
import '../../widgets/botones.dart';

/// Editar nombre y correo (PUT /api/usuarios/me).
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _correo;
  bool _guardando = false;
  Map<String, String> _erroresServidor = {};

  @override
  void initState() {
    super.initState();
    final usuario = context.read<AuthProvider>().usuario!;
    _nombre = TextEditingController(text: usuario.nombre);
    _correo = TextEditingController(text: usuario.correo);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final actual = auth.usuario!;
    final nombreNuevo = _nombre.text.trim();
    final correoNuevo = _correo.text.trim();
    // Solo se envía lo que cambió (el backend exige al menos un campo)
    if (nombreNuevo == actual.nombre && correoNuevo.toLowerCase() == actual.correo) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _guardando = true);
    try {
      final usuario = await context.read<AuthService>().actualizarPerfil(
            nombre: nombreNuevo != actual.nombre ? nombreNuevo : null,
            correo: correoNuevo.toLowerCase() != actual.correo ? correoNuevo : null,
          );
      auth.actualizarUsuario(usuario);
      if (!mounted) return;
      mostrarMensaje(context, 'Perfil actualizado');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _erroresServidor = e.codigo == 409 ? {'correo': e.mensaje} : e.errores;
      });
      if (_erroresServidor.isEmpty) mostrarMensaje(context, e.mensaje, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: Form(
          key: _formulario,
          child: ListView(
            padding: const EdgeInsets.all(AppMedidas.margenPantalla),
            children: [
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                validator: Validadores.nombre,
                forceErrorText: _erroresServidor['nombre'],
                onChanged: (_) => setState(() => _erroresServidor = {}),
                decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline_rounded)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: Validadores.correo,
                forceErrorText: _erroresServidor['correo'],
                onChanged: (_) => setState(() => _erroresServidor = {}),
                decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.mail_outline_rounded)),
              ),
              const SizedBox(height: 28),
              PillButton(texto: 'Guardar cambios', cargando: _guardando, onPressed: _guardar),
            ],
          ),
        ),
      ),
    );
  }
}
