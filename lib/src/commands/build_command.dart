import 'dart:async';

import 'package:anvil/anvil.dart';
import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/build_step/build_aliases.dart';
import 'package:anvil/src/build_step/build_content.dart';
import 'package:anvil/src/build_step/build_sitemap.dart';
import 'package:anvil/src/build_step/build_styles.dart';
import 'package:anvil/src/build_step/build_taxonomy.dart';
import 'package:anvil/src/build_step/copy_static_files.dart';
import 'package:anvil/src/build_step/create_data_tree.dart';
import 'package:anvil/src/build_step/parse_content.dart';
import 'package:args/command_runner.dart';
import 'package:anvil/src/commands/serve_command.dart';
import 'package:anvil/src/config.dart';
import 'package:anvil/src/errors.dart';
import 'package:anvil/src/file_system.dart';
import 'package:anvil/src/log.dart';
import 'package:anvil/src/search.dart';
import 'package:anvil/src/util/maybe.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;

class BuildCommand extends Command<int> {
  BuildCommand(this._config) {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show more logs.',
      defaultsTo: false,
      negatable: false,
    );
  }

  final Config? _config;

  @override
  final name = 'build';

  @override
  final description = 'Build static files.';

  final _stopwatch = Stopwatch();

  /// Reload script is included when build is triggered using [ServeCommand].
  ///
  /// This needs to generate new instance on each access. HTML library probably
  /// works with references and mutates the node after usage. Therefore, when
  /// settings this field as `late final`, it will be inserted into DOM only
  /// once and subsequent uses fail.
  html_dom.DocumentFragment get script {
    return html_parser.parseFragment(
      '<script src="http://127.0.0.1:${_config!.serve.port}/reload.js"></script>',
    );
  }

  @override
  FutureOr<int> run() {
    if (_config == null) {
      log.error('No $kAnvilConfigFile present in the current directory');
      return 1;
    }
    final result = build(_config!);
    return result.when(
          () => 0,
          (value) {
        log.error(value);
        return 1;
      },
    );
  }

  Maybe<BuildError> build(Config config, {
    bool isServe = false,
  }) {
    log.info('Building');
    _stopwatch.start();

    final steps = [
      ParseContent(config: config),
      BuildTaxonomy(config: config),
      CreateDataTree(config: config),
      BuildAliases(config: config),
      BuildContent(config: config),
      CopyStaticFiles(config: config),
      BuildSitemap(config: config),
      BuildStyles(config: config),
      if (config.build.generateSearchIndex)
        BuildSearchIndex(config: config)
    ];

    var data = BuildData(serve: isServe);

    for (final step in steps) {
      final result = step.run(data);

      if (result.isError) {
        return Just(result.error);
      }
      data = result.value;
    }

    _stopwatch.stop();
    log.info(
      'Build done in ${_stopwatch.elapsedMilliseconds}ms '
          '(${data.pages!.length} pages)',
    );
    _stopwatch.reset();
    return const Nothing();
  }
}
