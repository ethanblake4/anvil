import 'package:ansicolor/ansicolor.dart';
import 'package:args/command_runner.dart';
import 'package:anvil/src/commands/build_command.dart';
import 'package:anvil/src/commands/init_command.dart';
import 'package:anvil/src/commands/new_command.dart';
import 'package:anvil/src/commands/serve_command.dart';
import 'package:anvil/src/file_system.dart';

export 'src/assets/live_reload.dart';
export 'src/build/build_config.dart';
export 'src/build/content_parser.dart';
export 'src/config.dart';
export 'src/content/content.dart';
export 'src/content/content.dart';
export 'src/content/page.dart';
export 'src/content/redirect_page.dart';
export 'src/content/section.dart';
export 'src/data.dart';
export 'src/errors.dart';
export 'src/file_system.dart';
export 'src/git_util.dart';
export 'src/markdown/markdown_file.dart';
export 'src/search.dart';
export 'src/serve/local_server.dart';
export 'src/serve/serve_config.dart';
export 'src/serve/watch.dart';
export 'src/sitemap_builder.dart';
export 'src/taxonomy.dart';
export 'src/template/templates_config.dart';
export 'src/yaml.dart';

/// [Anvil] defines the main executable
class Anvil {

  final runner = CommandRunner<int>('anvil', 'Anvil Static Site Generator');

  Future<int?> call(List<String> args) async {

    final configOrError = await getConfig();
    final config = configOrError.isError ? null : configOrError.value;

    runner
        ..addCommand(InitCommand())
        ..addCommand(BuildCommand(config))
        ..addCommand(ServeCommand(config))
        ..addCommand(NewCommand(config));

    return runner.run(args);
  }
}
