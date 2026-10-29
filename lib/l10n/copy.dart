import 'package:flutter/widgets.dart';

enum CopyKey {
  subtitle,
  search,
  all,
  pending,
  completed,
  clearFilters,
  empty,
  markComplete,
  reopen,
  loading,
  offline,
  timeout,
  retry,
  storageError,
  notice,
  scenario,
  connected,
  offlineScenario,
  slowScenario,
  demo,
  completedCount,
  saving,
  missing,
  observe,
  review,
  maintain,
}

const translations = <String, Map<CopyKey, String>>{
  'en': {
    CopyKey.subtitle: 'Your field tasks',
    CopyKey.search: 'Search tasks',
    CopyKey.all: 'All',
    CopyKey.pending: 'Pending',
    CopyKey.completed: 'Completed',
    CopyKey.clearFilters: 'Clear search and filters',
    CopyKey.empty: 'No tasks match these filters.',
    CopyKey.markComplete: 'Mark complete',
    CopyKey.reopen: 'Mark pending',
    CopyKey.loading: 'Updating the demo list…',
    CopyKey.offline: 'The update is unavailable. The demo list is still here.',
    CopyKey.timeout: 'The demo response took too long. You can try again.',
    CopyKey.retry: 'Try again',
    CopyKey.storageError:
        'Local storage is unavailable. Retry before making changes.',
    CopyKey.notice:
        'Fictional tasks. Completion is saved on this device. No location is collected.',
    CopyKey.scenario: 'Demo scenarios',
    CopyKey.connected: 'Available data',
    CopyKey.offlineScenario: 'Simulated failure',
    CopyKey.slowScenario: 'Slow response',
    CopyKey.demo: 'Demo',
    CopyKey.completedCount: 'Completed',
    CopyKey.saving: 'Saving…',
    CopyKey.missing: 'This task is no longer available.',
    CopyKey.observe: 'Observe',
    CopyKey.review: 'Review',
    CopyKey.maintain: 'Prepare',
  },
  'es': {
    CopyKey.subtitle: 'Tus tareas de campo',
    CopyKey.search: 'Buscar tareas',
    CopyKey.all: 'Todas',
    CopyKey.pending: 'Pendientes',
    CopyKey.completed: 'Completadas',
    CopyKey.clearFilters: 'Borrar búsqueda y filtros',
    CopyKey.empty: 'No hay tareas para estos filtros.',
    CopyKey.markComplete: 'Marcar completada',
    CopyKey.reopen: 'Marcar pendiente',
    CopyKey.loading: 'Actualizando la lista de demostración…',
    CopyKey.offline:
        'No se pudo actualizar. Conservamos la lista de demostración.',
    CopyKey.timeout:
        'La respuesta de demostración tardó demasiado. Puedes reintentar.',
    CopyKey.retry: 'Reintentar',
    CopyKey.storageError:
        'El guardado local no está disponible. Reintenta antes de modificar datos.',
    CopyKey.notice:
        'Tareas ficticias. El estado se guarda en este dispositivo. No se recoge ubicación.',
    CopyKey.scenario: 'Escenarios de demostración',
    CopyKey.connected: 'Datos disponibles',
    CopyKey.offlineScenario: 'Fallo simulado',
    CopyKey.slowScenario: 'Respuesta lenta',
    CopyKey.demo: 'Demo',
    CopyKey.completedCount: 'Completadas',
    CopyKey.saving: 'Guardando…',
    CopyKey.missing: 'Esta tarea ya no está disponible.',
    CopyKey.observe: 'Observar',
    CopyKey.review: 'Revisar',
    CopyKey.maintain: 'Preparar',
  },
};

String copy(BuildContext context, CopyKey key) =>
    (translations[Localizations.localeOf(context).languageCode] ??
    translations['en']!)[key]!;
