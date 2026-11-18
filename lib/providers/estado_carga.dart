/// Estados de una pantalla que carga datos del backend.
enum EstadoCarga {
  /// Todavía no se pidió nada.
  inicial,

  /// Esperando la respuesta (se ve un indicador de carga).
  cargando,

  /// Hay datos para mostrar.
  listo,

  /// Falló la carga (se ve ErrorState con «Reintentar»).
  error,
}
