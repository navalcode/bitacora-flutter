# Bitácora

[English](README.md)

Demo Flutter original de tareas de campo para observar estado asíncrono, recuperación y persistencia local. Seis tareas ficticias permiten buscar, filtrar pendientes/completadas, consultar detalles y guardar su estado en el dispositivo.

Los flavors `dev` y `prod` son de demostración. No necesita cuentas, API keys, ubicación ni backend. Textos, datos e icono de cuaderno son originales; los iconos de interfaz conservan las licencias del framework.

| Pendientes tras guardar una tarea | Detalle guardado |
|---|---|
| ![Tareas pendientes](docs/images/board.png) | ![Tarea guardada](docs/images/detail.png) |

Capturas reales de emulador API 37 generadas durante el recorrido de integración.

## Probar

1. Abre una tarea y márcala como completada.
2. Vuelve y compara Todas, Pendientes y Completadas.
3. Busca títulos españoles con o sin acentos en las vocales.
4. En el menú de laboratorio, selecciona Fallo simulado o Respuesta lenta.
5. La lista incluida sigue disponible. Vuelve a Datos disponibles para recuperar.
6. Reinicia: el estado confirmado permanece guardado localmente.

Los escenarios modifican la fuente de demostración. El catálogo viene incluido; no es una caché de un servicio de producción.

## Ejecutar y comprobar

Validado con **Flutter 3.38.7**, Dart 3.10.7, JDK 17 y Android SDK 36. Android requiere API 24 o superior. `pubspec.lock` fija versiones y hashes de dependencias.

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter run --flavor dev
flutter build apk --debug --flavor prod
flutter build appbundle --release --flavor prod
flutter build web --dart-define=APP_ENV=dev --no-web-resources-cdn --pwa-strategy=none
```

Ambos flavors Android usan `lib/main.dart`; el build selecciona el entorno. Un nombre desconocido falla explícitamente. En web, `APP_ENV=dev` o `prod` selecciona la etiqueta, sin conectar servicios reales.

Flutter puede elegir el JDK de Android Studio antes que `JAVA_HOME`. Si la instalación compartida selecciona uno incompatible, configura JDK 17 para este proyecto mediante propiedades locales de Gradle o `GRADLE_OPTS=-Dorg.gradle.java.home=/ruta/a/jdk-17`. No versiones rutas locales. No hay clave o firma de producción configurada.

Prueba conectada y capturas, sustituyendo el identificador del dispositivo:

```sh
flutter test integration_test/app_test.dart --flavor dev -d emulator-5554
flutter drive --driver test_driver/capture.dart --target integration_test/app_test.dart --flavor dev -d emulator-5554 --keep-app-running
```

El recorrido reinicia los IDs de esta demo y deja una tarea ficticia completada. El driver guarda los dos PNG revisados en `docs/images/`.

## Leer el código

- [`tasks.dart`](lib/domain/tasks.dart): modelos, contratos, generaciones de peticiones, deadline y estado de almacenamiento confirmado.
- [`completion_preferences.dart`](lib/data/completion_preferences.dart): adaptador real de preferencias.
- [`main.dart`](lib/main.dart): grafo explícito, navegación lista/detalle y propiedad del estado.
- [`copy.dart`](lib/l10n/copy.dart): recursos ES/EN y fallback.
- [`controller_test.dart`](test/controller_test.dart): fallos, recuperación, resultados obsoletos, disposición, timeout y estado de solo lectura.
- [`app_test.dart`](integration_test/app_test.dart): persistencia nativa y capturas.

[Arquitectura y decisiones](docs/ARCHITECTURE.md), en inglés, explica la diferencia entre descartar Futures obsoletos y cancelar transporte, y por qué un fallo de lectura bloquea escrituras.

## Alcance verificado

El 29 de octubre de 2026 pasan **17 tests del controlador, cinco de widgets y un recorrido de persistencia nativa**. Analyzer no tiene avisos. Se comprueban 360×800 y texto 1,8. Se generan APK debug dev/prod, AAB prod release y web. El arranque normal Android conserva la tarea tras sustituir el APK y reiniciar el proceso.

La revisión manual web cubre detalle, completar, filtros, persistencia tras recarga y fallo/recuperación. La auditoría consultiva del AAB mide 0,95 MB DEX, alineación nativa correcta y ninguna advertencia. No equivale a aprobación de tienda. No se ha validado iOS ni un dispositivo físico.

La CI preparada comprueba analyzer/tests, flavors/release Android, web y un recorrido en emulador. El resultado remoto se registra por separado; un workflow escrito no acredita éxito.

## Licencia

Código, textos, datos e ilustraciones vectoriales originales: [MIT](LICENSE), copyright 2026 Manuel Naval. [Avisos de terceros](THIRD_PARTY.md) conserva las licencias de Flutter, plantillas y dependencias.
