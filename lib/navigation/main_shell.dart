import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/navegacion_provider.dart';
import '../screens/habits/habitos_screen.dart';
import '../screens/health/salud_screen.dart';
import '../screens/home/mi_dia_screen.dart';
import '../screens/study/smartstudy_screen.dart';
import '../theme/app_theme.dart';

/// Estructura principal después del login: las 4 pestañas y la barra inferior.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final navegacion = context.watch<NavegacionProvider>();
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
