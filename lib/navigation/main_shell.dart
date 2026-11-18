import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habitos_provider.dart';
import '../providers/mi_dia_provider.dart';
import '../providers/navegacion_provider.dart';
import '../providers/smartstudy_provider.dart';
import '../screens/habits/habitos_screen.dart';
import '../screens/health/salud_screen.dart';
import '../screens/home/mi_dia_screen.dart';
import '../screens/study/smartstudy_screen.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Estructura principal después del login: las 4 pestañas y la barra inferior.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int? _indiceAnterior;

  /// Al entrar a una pestaña se recargan sus datos (pudieron cambiar en otra pestaña).
  /// Si falla, la pantalla conserva lo que ya mostraba.
  Future<void> _recargar(int indice) async {
    try {
      switch (indice) {
        case NavegacionProvider.miDia:
          await context.read<MiDiaProvider>().cargar(silencioso: true);
        case NavegacionProvider.smartStudy:
          await context.read<SmartStudyProvider>().cargar(silencioso: true);
        case NavegacionProvider.habitos:
          await context.read<HabitosProvider>().cargar(silencioso: true);
      }
    } on ApiException {
      // Sin conexión: se mantiene lo último que se cargó
    }
  }

  @override
  Widget build(BuildContext context) {
    final navegacion = context.watch<NavegacionProvider>();

    // La pestaña cambió (desde la barra, «Ver todo» o un acceso rápido): recargar
    if (_indiceAnterior != null && _indiceAnterior != navegacion.indice) {
      final indice = navegacion.indice;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _recargar(indice);
      });
    }
    _indiceAnterior = navegacion.indice;

    return Scaffold(
      // IndexedStack conserva el estado de cada pestaña al cambiar entre ellas
      body: IndexedStack(
        index: navegacion.indice,
        children: const [MiDiaScreen(), SmartStudyScreen(), HabitosScreen(), SaludScreen()],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borde))),
        child: NavigationBar(
          selectedIndex: navegacion.indice,
          onDestinationSelected: (i) => context.read<NavegacionProvider>().irA(i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today_rounded), label: 'Mi Día'),
            NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school_rounded), label: 'SmartStudy'),
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline_rounded),
              selectedIcon: Icon(Icons.check_circle_rounded),
              label: 'Hábitos',
            ),
            NavigationDestination(icon: Icon(Icons.favorite_outline_rounded), selectedIcon: Icon(Icons.favorite_rounded), label: 'Salud'),
          ],
        ),
      ),
    );
  }
}
