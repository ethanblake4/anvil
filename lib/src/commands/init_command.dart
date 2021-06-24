import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:anvil/src/config.dart';
import 'package:anvil/src/file_system.dart';
import 'package:anvil/src/log.dart';
import 'package:anvil/src/utils.dart';
import 'package:anvil/src/yaml.dart';

class InitCommand extends Command<int> {
  @override
  final name = 'init';

  @override
  String get summary => 'Create new Anvil project.';

  @override
  final description = _description;

  @override
  FutureOr<int> run() async {
    final projectDir = argResults!.rest.isEmpty ? '.' : argResults!.rest.first;
    final generateInCurrentDir = projectDir == '.';

    if (!generateInCurrentDir) {
      log.info('Initializing project in $projectDir directory');
      await fs.directory(projectDir).create();
    } else {
      log.info('Initializing project in current directory...');
    }

    try {
      await _initConfig(projectDir);

      await fs.directory('$projectDir/content').create();
      await fs.directory('$projectDir/templates').create();
      await fs.directory('$projectDir/static').create();
      await fs.directory('$projectDir/styles').create();
      await fs.directory('$projectDir/data').create();
      await fs.directory('$projectDir/types').create();
    } catch (e) {
      log.error(e);
      return 1;
    }

    final serverStartHelp = generateInCurrentDir
        ? 'Start server by `anvil serve`'
        : 'Start server by `cd $projectDir && anvil serve`';
    log.info(
      'Site initialized successfully\n       $serverStartHelp',
    );

    return 0;
  }

  Future<void> _initConfig(String root) async {
    final configFile =
        await fs.file(Path.join(root, kAnvilConfigFile))
            .create(recursive: true);
    final config = await configFile.readAsString();

    if (config.trim().isNotEmpty) {
      log.warning('WARNING: $kAnvilConfigFile file already exists.');
      return;
    }

    log.info('Populating with default values...');

    final defaultConfig = Config.initial().toMap();
    final yaml = jsonToYaml(defaultConfig);

    try {
      await configFile.writeAsString(yaml);
    } catch (e) {
      log.error(e);
    }
  }
}

const _description = '''
Create new Anvil project.

Use `anvil init` to initialize project in current repository.
If you want to initialize project in subdirectory call `anvil init folder_name`.
''';
