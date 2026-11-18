import 'api_service.dart';
import 'auth_service.dart';
import 'habitos_service.dart';
import 'mi_dia_service.dart';
import 'preferencias_service.dart';
import 'salud_service.dart';
import 'smartstudy_service.dart';

/// Todos los servicios de la app, creados una sola vez y compartiendo el mismo ApiService
/// (así todos usan el mismo token).
class Servicios {
  Servicios(this.api)
      : auth = AuthService(api),
        smartStudy = SmartStudyService(api),
        habitos = HabitosService(api),
        salud = SaludService(api),
        miDia = MiDiaService(api, HabitosService(api)),
        preferencias = PreferenciasService();

  final ApiService api;
  final AuthService auth;
  final SmartStudyService smartStudy;
  final HabitosService habitos;
  final SaludService salud;
  final MiDiaService miDia;
  final PreferenciasService preferencias;
}
