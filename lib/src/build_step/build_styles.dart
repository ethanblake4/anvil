import 'package:anvil/anvil.dart';
import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/build_step/build_step.dart';
import 'package:anvil/src/config.dart';
import 'package:anvil/src/util/either.dart';
import 'package:anvil/src/utils.dart';
import 'package:sass/sass.dart' as sass;

class BuildStyles extends BuildStep {
  const BuildStyles({
    required Config config,
  }) : super(config: config);

  @override
  Either<BuildError, BuildData> run(BuildData data) {
    final importer = sass.FilesystemImporter(config.build.stylesDir);
    final mainStyle = Path.join(config.build.stylesDir, 'main.scss');

    try {
      final css = sass.compile(mainStyle, importers: [importer], style: sass.OutputStyle.compressed);

      createFile('styles.css', css);
    } on sass.SassException catch (e) {
      final s = e.span;
      return Left(BuildError('Error compiling ${s.file.url} (at ${s.start.line}:${s.start.offset}): ${e.message}'));
    } catch (e) {
      return const Left(BuildError('Error building styles'));
    }

    return Right(data);
  }
}
