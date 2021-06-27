import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:anvil/src/assets/live_reload.dart';
import 'package:anvil/src/commands/build_command.dart';
import 'package:anvil/src/config.dart';
import 'package:anvil/src/file_system.dart';
import 'package:anvil/src/log.dart';
import 'package:anvil/src/serve/local_server.dart';
import 'package:anvil/src/serve/watch.dart';
import 'package:glob/glob.dart';

/// Build and serve static files on local server with live-reload support.
///
/// Only following files and folders are watched:
///   config.yaml
///   content/
///   data/
///   static/
///   templates/
///   styles/
///
/// Changing other files will not trigger rebuild.
class ServeCommand extends Command<int> {
  ServeCommand(this._config) {
    argParser
      ..addOption('address', abbr: 'a', defaultsTo: '127.0.0.1')
      ..addOption('port', abbr: 'p', defaultsTo: '4040')
      ..addOption('websocket-port', defaultsTo: '4041');
  }

  @override
  final String name = 'serve';

  @override
  final String summary = 'Start local server.';

  @override
  final String description = _description;

  final Config? _config;

  late BuildCommand buildCommand;

  @override
  FutureOr<int> run() {
    if(_config == null) {
      log.error('No $kAnvilConfigFile present in the current directory');
      return 1;
    }

    log.verbose = _config!.serve.verbose;

    return _serve(_config!);
  }

  void _rebuild(Config config) {
    final result = buildCommand.build(
      config,
      isServe: true,
    );
    return result.when(
      () => 0,
      log.error,
    );
  }

  Future<int> _serve(Config config) async {
    buildCommand = BuildCommand(config);
    // Build once before starting server to ensure there is something to show.
    _rebuild(config);

    try {
      await setupReloadScript(config);
      log.debug('Reload script copied');
    } catch (e) {
      log.error('Failed to copy reload script', error: e);
      return 1;
    }

    final _onReload = StreamController<void>();

    final glob = Glob(
      '{'
      '$kAnvilConfigFile,'
      '${config.build.contentDir}/**,'
      '${config.build.dataDir}/**,'
      '${config.build.stylesDir}/**,'
      '${config.build.staticDir}/**,'
      '${config.build.templatesDir}/**'
      '}',
    );

    watch('.', files: glob).listen((event) {
      // ignore: avoid_print
      print('');
      log.info('Event: $event');
      if (event.path.startsWith(config.build.templatesDir)) {
        final templatePath =
            event.path.replaceFirst('${config.build.templatesDir}/', '');
        final content = fs.file(event.path).readAsStringSync();
        config.environment.fromString(
          content,
          path: templatePath,
        );
      }
      _rebuild(config);
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
}

const _description = '''Starts local web server and watches for file changes. 
After every change the website will be rebuilt.''';
