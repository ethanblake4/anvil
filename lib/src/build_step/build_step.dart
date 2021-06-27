import 'package:anvil/anvil.dart';
import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/file_system.dart';
import 'package:anvil/src/util/either.dart';
import 'package:anvil/src/utils.dart';
import 'package:file/file.dart';

abstract class BuildStep {
  const BuildStep({required this.config});

  final Config config;

  Either<BuildError, BuildData> run(BuildData data);

  void createFile(String name, String content) {
    fs
        .file(Path.join(config.build.publicDir, name))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  /// Get a directory or an error if it doesn't exist
  Either<BuildError, Directory> requireDirectory(String path) {
    final directory = fs.directory(path);
    if (directory.existsSync()) {
      return Right(directory);
    } else {
      return Left(BuildError('Directory ${directory.path} does not exists'));
    }
  }
}