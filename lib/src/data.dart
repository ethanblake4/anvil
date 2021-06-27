import 'dart:convert';

import 'package:anvil/src/config.dart';
import 'package:anvil/src/errors.dart';
import 'package:anvil/src/file_system.dart';
import 'package:anvil/src/log.dart';
import 'package:anvil/src/utils.dart';
import 'package:file/file.dart';

/// Parse JSON files inside `data_dir` and create data Map which
/// you can access inside templates.
///
/// Each subfolder inside `data_dir` becomes a key inside the returned
/// Map<String, dynamic>. Therefore it does not matter if you use single file
/// with deeply nested data or split the data into more files (data tree will
/// be the same).
///
/// See `example` directory for reference.
Map<String, Object?> parseDataTree(
  Config config, {
  String? path,
}) {
  final data = <String, Object?>{};
  path ??= config.build.dataDir;
  final nodes = fs.directory(path).listSync().toList();

  for (final e in nodes) {
    e.when(
      directory: (directory) {
        final name = Path.basename(directory.path);
        data[name] = parseDataTree(config, path: directory.path);
      },
      file: (file) {
        final name = Path.basenameWithoutExtension(file.path);
        try {
          final dynamic content = _parseData(file);
          data[name] = content;
        } catch (e) {
          log.error(e);
        }
      },
    );
  }

  return data;
}

dynamic _parseData(File file) {
  final extension =
      Path.extension(file.path).toLowerCase().replaceFirst('.', '');
  final content = file.readAsStringSync();

  if (extension != 'json') {
    throw BuildError('Invalid data format: $extension');
  }

  return json.decode(content);
}
