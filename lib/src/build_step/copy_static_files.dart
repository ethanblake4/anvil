import 'package:anvil/anvil.dart';
import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/build_step/build_step.dart';
import 'package:anvil/src/log.dart';
import 'package:anvil/src/util/either.dart';
import 'package:file/file.dart';

class CopyStaticFiles extends BuildStep {
  CopyStaticFiles({required Config config}) : super(config: config);

  late Map<String, Object?> data;

  @override
  Either<BuildError, BuildData> run(BuildData data) {
    try {
      final staticDir = getStaticDirectory(config);

      final staticContent = staticDir.listSync(recursive: true).toList();
      final directories = staticContent.whereType<Directory>();
      final files = staticContent.whereType<File>();

      for (final directory in directories) {
        final path = directory.path.replaceFirst(
          config.build.staticDir,
          config.build.publicDir,
        );
        fs.directory(path).createSync(recursive: true);
      }

      for (final file in files) {
        file.copySync(
          file.path.replaceFirst(
            config.build.staticDir,
            config.build.publicDir,
          ),
        );
      }

      log.debug('Static files copied');
    } catch (e) {
      log.info('Skipping static directory.');
    }

    return Right(data);
  }
}
