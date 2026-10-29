import 'package:shared_preferences/shared_preferences.dart';
import '../domain/tasks.dart';

/// Stores only IDs of completed fictional tasks. No credentials or personal data.
class PreferencesCompletionStore implements CompletionStore {
  PreferencesCompletionStore(this.preferences);
  final SharedPreferencesAsync preferences;
  static const key = 'bitacora.completed.v1';

  @override
  Future<Set<String>> load() async =>
      (await preferences.getStringList(key) ?? []).toSet();

  @override
  Future<void> save(Set<String> ids) =>
      preferences.setStringList(key, ids.toList()..sort());
}
