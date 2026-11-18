import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/smartstudy_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/campos.dart';
import '../../widgets/estados.dart';
import '../../widgets/life_card.dart';
import 'materia_form_screen.dart';

/// Lista de materias: tocar una para editarla o eliminarla; «+» para crear.
class MateriasScreen extends StatelessWidget {
  const MateriasScreen({super.key});

  void _abrir(BuildContext context, Widget pantalla) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SmartStudyProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Materias')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nueva materia',
        onPressed: () => _abrir(context, const MateriaFormScreen()),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: p.materias.isEmpty
            ? Center(
                child: EmptyState(
                  icono: Icons.school_rounded,
                  titulo: 'Aún no tienes materias',
                  textoAccion: 'Crear materia',
                  onAccion: () => _abrir(context, const MateriaFormScreen()),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppMedidas.margenPantalla, 8, AppMedidas.margenPantalla, 96),
                itemCount: p.materias.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final materia = p.materias[i];
                  final pendientes = p.tareas.where((t) => t.materiaId == materia.id && !t.completada).length;
                  return LifeCard(
                    padding: const EdgeInsets.all(16),
                    radio: AppMedidas.radioItem + 4,
                    onTap: () => _abrir(context, MateriaFormScreen(materia: materia)),
                    child: Row(
                      children: [
                        IconoMateria(color: AppColors.paletaMaterias[p.colorDe(materia.id)]),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(materia.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              Text(
                                [
                                  if (materia.docente != null) materia.docente!,
                                  '$pendientes pendiente${pendientes == 1 ? '' : 's'}',
                                ].join(' · '),
                                style: const TextStyle(fontSize: 12, color: AppColors.textoSecundario),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textoSecundario),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
