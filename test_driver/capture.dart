import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          if (!{
            'board',
            'detail',
            'es-board',
            'es-detail',
            'es-large-board',
            'es-large-detail',
          }.contains(name)) {
            return false;
          }
          final directory = Directory('docs/images');
          await directory.create(recursive: true);
          await File('${directory.path}/$name.png').writeAsBytes(bytes);
          return true;
        },
  );
}
