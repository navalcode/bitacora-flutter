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
  storageReadError,
  storageWriteError,
  reloadStatus,
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
    CopyKey.empty: 'No tasks match. Change your search or clear the filters.',
    CopyKey.markComplete: 'Mark complete',
    CopyKey.reopen: 'Mark pending',
    CopyKey.loading: 'Updating tasks…',
    CopyKey.offline:
        'The update failed. The task list is still available. Choose Normal loading in Loading scenarios.',
    CopyKey.timeout:
        'Loading took too long. Retry or choose Normal loading in Loading scenarios.',
    CopyKey.retry: 'Try again',
    CopyKey.storageReadError:
        'Saved task status could not be read. Reload tasks to enable changes.',
    CopyKey.storageWriteError:
        'Saving could not be confirmed. Reload tasks before trying again.',
    CopyKey.reloadStatus: 'Reload tasks',
    CopyKey.notice: 'Sample tasks. Changes are saved on this device.',
    CopyKey.scenario: 'Loading scenarios',
    CopyKey.connected: 'Normal loading',
    CopyKey.offlineScenario: 'Simulated failure',
    CopyKey.slowScenario: 'Slow response',
    CopyKey.demo: 'Demo',
    CopyKey.completedCount: 'Completed',
    CopyKey.saving: 'Saving…',
    CopyKey.missing:
        'This task is no longer available. Go back to the list to choose another.',
    CopyKey.observe: 'Observation',
    CopyKey.review: 'Review',
    CopyKey.maintain: 'Preparation',
  },
  'es': {
    CopyKey.subtitle: 'Tus tareas de campo',
    CopyKey.search: 'Buscar tareas',
    CopyKey.all: 'Todas',
    CopyKey.pending: 'Pendientes',
    CopyKey.completed: 'Completadas',
    CopyKey.clearFilters: 'Borrar búsqueda y filtros',
    CopyKey.empty:
        'No hay tareas que coincidan. Cambia la búsqueda o quita los filtros.',
    CopyKey.markComplete: 'Marcar completada',
    CopyKey.reopen: 'Marcar pendiente',
    CopyKey.loading: 'Actualizando tareas…',
    CopyKey.offline:
        'No se ha podido actualizar. La lista sigue disponible. Elige Carga normal en Escenarios de carga.',
    CopyKey.timeout:
        'La carga ha tardado demasiado. Reintenta o elige Carga normal en Escenarios de carga.',
    CopyKey.retry: 'Reintentar',
    CopyKey.storageReadError:
        'No se puede leer el estado guardado. Vuelve a cargar las tareas para poder editarlas.',
    CopyKey.storageWriteError:
        'No se ha podido confirmar el guardado. Recarga las tareas antes de intentarlo de nuevo.',
    CopyKey.reloadStatus: 'Recargar tareas',
    CopyKey.notice:
        'Tareas de ejemplo. Los cambios se guardan en este dispositivo.',
    CopyKey.scenario: 'Escenarios de carga',
    CopyKey.connected: 'Carga normal',
    CopyKey.offlineScenario: 'Fallo simulado',
    CopyKey.slowScenario: 'Respuesta lenta',
    CopyKey.demo: 'Demo',
    CopyKey.completedCount: 'Completadas',
    CopyKey.saving: 'Guardando…',
    CopyKey.missing:
        'Esta tarea ya no está disponible. Vuelve a la lista para elegir otra.',
    CopyKey.observe: 'Observación',
    CopyKey.review: 'Revisión',
    CopyKey.maintain: 'Preparación',
  },
};

String copy(BuildContext context, CopyKey key) =>
    (translations[Localizations.localeOf(context).languageCode] ??
    translations['en']!)[key]!;
