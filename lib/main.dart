import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/completion_preferences.dart';
import 'domain/tasks.dart';
import 'l10n/copy.dart';
import 'ui/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const declared = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  final environment = AppEnvironment.parse(appFlavor ?? declared);
  final model = TaskController(
    BundledTaskSource(),
    PreferencesCompletionStore(SharedPreferencesAsync()),
  );
  runApp(BitacoraApp(model: model, environment: environment));
  unawaited(model.initialize());
}

/// The root takes ownership of the injected controller's lifetime.
class BitacoraApp extends StatefulWidget {
  const BitacoraApp({
    super.key,
    required this.model,
    required this.environment,
    this.locale,
  });
  final TaskController model;
  final AppEnvironment environment;
  final Locale? locale;

  @override
  State<BitacoraApp> createState() => _BitacoraAppState();
}

class _BitacoraAppState extends State<BitacoraApp> {
  @override
  void dispose() {
    widget.model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Bitácora',
    debugShowCheckedModeBanner: false,
    locale: widget.locale,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('es'), Locale('en')],
    localeResolutionCallback: (locale, _) =>
        Locale(locale?.languageCode == 'es' ? 'es' : 'en'),
    theme: buildBitacoraTheme(),
    builder: (context, child) => ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
    home: TaskBoard(model: widget.model, environment: widget.environment),
  );
}

class TaskBoard extends StatefulWidget {
  const TaskBoard({super.key, required this.model, required this.environment});
  final TaskController model;
  final AppEnvironment environment;
  @override
  State<TaskBoard> createState() => _TaskBoardState();
}

class _TaskBoardState extends State<TaskBoard> {
  late final TextEditingController search = TextEditingController(
    text: widget.model.query,
  );
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.model,
    builder: (context, _) {
      final model = widget.model;
      final language = Localizations.localeOf(context).languageCode;
      final tasks = model.visible(language);
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bitácora'),
          actions: [
            PopupMenuButton<DemoScenario>(
              tooltip: copy(context, CopyKey.scenario),
              icon: const Icon(Icons.science_outlined),
              onSelected: (value) => unawaited(model.selectScenario(value)),
              itemBuilder: (context) => DemoScenario.values
                  .map(
                    (value) => PopupMenuItem(
                      value: value,
                      child: Text(copy(context, scenarioKey(value))),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            key: const PageStorageKey('task-list'),
            padding: const EdgeInsets.all(20),
            children: [
              Semantics(
                header: true,
                child: Text(
                  copy(context, CopyKey.subtitle),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 20,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (model.storageReady)
                    Text(
                      '${copy(context, CopyKey.completedCount)}: ${model.completed.length} / ${model.items.length}',
                    ),
                  Text(
                    '${copy(context, CopyKey.demo)} · ${widget.environment.name}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                key: const ValueKey('search'),
                controller: search,
                onChanged: model.queryChanged,
                decoration: InputDecoration(
                  labelText: copy(context, CopyKey.search),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: TaskFilter.values
                    .map(
                      (filter) => ChoiceChip(
                        key: ValueKey('filter-${filter.name}'),
                        selected: model.filter == filter,
                        label: Text(copy(context, filterKey(filter))),
                        onSelected: (_) => model.filterChanged(filter),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              if (model.sync == SyncState.loading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(copy(context, CopyKey.loading)),
              ],
              if (model.sync == SyncState.offline ||
                  model.sync == SyncState.timeout)
                Notice(
                  text: copy(
                    context,
                    model.sync == SyncState.timeout
                        ? CopyKey.timeout
                        : CopyKey.offline,
                  ),
                  action: copy(context, CopyKey.retry),
                  onAction: () => unawaited(model.refresh()),
                ),
              if (model.storageError)
                Notice(
                  text: copy(
                    context,
                    model.storageReady
                        ? CopyKey.storageWriteError
                        : CopyKey.storageReadError,
                  ),
                  action: copy(context, CopyKey.reloadStatus),
                  onAction: () => unawaited(model.initialize()),
                ),
              if (model.saving)
                Text(
                  copy(context, CopyKey.saving),
                  key: const ValueKey('saving'),
                ),
              if (tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Text(copy(context, CopyKey.empty)),
                      TextButton(
                        onPressed: () {
                          search.clear();
                          model.queryChanged('');
                          model.filterChanged(TaskFilter.all);
                        },
                        child: Text(copy(context, CopyKey.clearFilters)),
                      ),
                    ],
                  ),
                ),
              ...tasks.map(
                (task) => Column(
                  children: [
                    ListTile(
                      key: ValueKey('task-${task.id}'),
                      leading: Semantics(
                        label: task.title(language),
                        child: Checkbox(
                          key: ValueKey('complete-${task.id}'),
                          value: model.completed.contains(task.id),
                          onChanged: !model.storageReady || model.saving
                              ? null
                              : (value) => unawaited(
                                  model.setCompleted(task.id, value!),
                                ),
                        ),
                      ),
                      title: Text(task.title(language)),
                      subtitle: Text(copy(context, areaKey(task.area))),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => open(task.id),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                copy(context, CopyKey.notice),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    },
  );

  void open(String id) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TaskDetail(model: widget.model, id: id),
    ),
  );
}

class TaskDetail extends StatelessWidget {
  const TaskDetail({super.key, required this.model, required this.id});
  final TaskController model;
  final String id;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: model,
    builder: (context, _) {
      final matching = model.items.where((task) => task.id == id);
      final task = matching.isEmpty ? null : matching.first;
      final language = Localizations.localeOf(context).languageCode;
      final completed = model.completed.contains(id);
      return Scaffold(
        appBar: AppBar(title: const Text('Bitácora')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (task == null)
                Text(copy(context, CopyKey.missing))
              else ...[
                Semantics(
                  header: true,
                  child: Text(
                    task.title(language),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      switch (task.area) {
                        TaskArea.observe => Icons.visibility_outlined,
                        TaskArea.review => Icons.fact_check_outlined,
                        TaskArea.maintain => Icons.construction_outlined,
                      },
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(copy(context, areaKey(task.area)))),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  task.detail(language),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                if (model.storageError)
                  Notice(
                    text: copy(
                      context,
                      model.storageReady
                          ? CopyKey.storageWriteError
                          : CopyKey.storageReadError,
                    ),
                    action: copy(context, CopyKey.reloadStatus),
                    onAction: () => unawaited(model.initialize()),
                  ),
                FilledButton.icon(
                  key: const ValueKey('detail-complete'),
                  onPressed: !model.storageReady || model.saving
                      ? null
                      : () => unawaited(model.setCompleted(id, !completed)),
                  icon: Icon(completed ? Icons.undo : Icons.check),
                  label: Text(
                    copy(
                      context,
                      model.saving
                          ? CopyKey.saving
                          : completed
                          ? CopyKey.reopen
                          : CopyKey.markComplete,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(copy(context, CopyKey.notice)),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.text,
    required this.action,
    required this.onAction,
  });
  final String text;
  final String action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text),
            TextButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    ),
  );
}

CopyKey filterKey(TaskFilter filter) => switch (filter) {
  TaskFilter.all => CopyKey.all,
  TaskFilter.pending => CopyKey.pending,
  TaskFilter.completed => CopyKey.completed,
};
CopyKey areaKey(TaskArea area) => switch (area) {
  TaskArea.observe => CopyKey.observe,
  TaskArea.review => CopyKey.review,
  TaskArea.maintain => CopyKey.maintain,
};
CopyKey scenarioKey(DemoScenario scenario) => switch (scenario) {
  DemoScenario.connected => CopyKey.connected,
  DemoScenario.offline => CopyKey.offlineScenario,
  DemoScenario.slow => CopyKey.slowScenario,
};
