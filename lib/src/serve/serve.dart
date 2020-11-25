import 'dart:async';

import 'package:blake/src/assets/reload_js.dart';
import 'package:blake/src/build/build.dart';
import 'package:blake/src/config.dart';
import 'package:blake/src/log.dart';
import 'package:blake/src/serve/local_server.dart';
import 'package:blake/src/serve/watch.dart';
import 'package:glob/glob.dart';

/// Build and serve static files on local server with live-reload support.
///
/// Only following files and folders are watched:
///   config.yaml
///   content/
///   data/
///   static/
///   templates/
///
/// Changing other files will not trigger rebuild.
Future<int> serve(Config config) async {
  // Build once before starting server to ensure there is something to show.
  await build(config);

  try {
    await setupReloadScript(config);
    log.debug('Reload script copied');
  } catch (e) {
    log.severe('Failed to copy reload script');
    return 1;
  }

  final _onReload = StreamController<void>();

  final glob = Glob(
    '{'
    'config.yaml,'
    '${config.build.contentDir}/**,'
    '${config.build.dataDir}/**,'
    '${config.build.staticDir}/**,'
    '${config.build.templatesDir}/**'
    '}',
  );

  watch('.', files: glob).listen((event) async {
    final stopwatch = Stopwatch()..start();
    await build(config);
    stopwatch.stop();
    _onReload.add(null);
  });

  log.debug(config.serve);

  await LocalServer(
    config.build.publicDir,
    address: config.serve.baseUrl.host,
    port: config.serve.baseUrl.port,
    websocketPort: config.serve.websocketPort,
    onReload: _onReload.stream.asBroadcastStream(),
  ).start();

  return 0;
}
