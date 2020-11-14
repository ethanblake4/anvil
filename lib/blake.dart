import 'package:args/command_runner.dart';
import 'package:blake/src/commands/build_command.dart';
import 'package:blake/src/commands/init_command.dart';
import 'package:blake/src/commands/serve_command.dart';
import 'package:blake/src/file_system.dart';

export 'src/build/build.dart';
export 'src/build/build_config.dart';
export 'src/content/content.dart';
export 'src/file_system.dart';
export 'src/serve/local_server.dart';
export 'src/serve/serve.dart';
export 'src/serve/serve_config.dart';

class Blake {
  final runner = CommandRunner<int>('blake', 'Blake Static Site Generator');

  Future<int> call(List<String> args) async {
    final config = await getConfig();

    runner
      ..addCommand(BuildCommand(config))
      ..addCommand(ServeCommand(config))
      ..addCommand(InitCommand());

    return runner.run(args);
  }
}

final blake = Blake();
