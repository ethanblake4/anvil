import 'package:anvil/anvil.dart';
import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/build_step/build_step.dart';
import 'package:anvil/src/shortcode.dart';
import 'package:anvil/src/util/either.dart';
import 'package:anvil/src/utils.dart';
import 'package:file/file.dart';

class ParseContent extends BuildStep {
  ParseContent({required Config config}) : super(config: config);

  @override
  Either<BuildError, BuildData> run(BuildData data) {
    final shortcodesDirPath = Path.join(
      config.build.templatesDir,
      'shortcodes',
    );
    final shortcodesDir = fs.directory(shortcodesDirPath);

    Iterable<ShortcodeTemplate> shortcodeTemplates;
    // TODO: Create shortcodes dir during initialization.
    if (shortcodesDir.existsSync()) {
      final shortcodeFiles = shortcodesDir.listSync();

      shortcodeTemplates = shortcodeFiles.whereType<File>().map<ShortcodeTemplate>((e) {
        return ShortcodeTemplate(
          name: Path.basenameWithoutExtension(e.path),
          template: e.readAsStringSync(),
        );
      });
    } else {
      shortcodeTemplates = [];
    }

    final contentDir = requireDirectory(config.build.contentDir);
    if (contentDir.isError) {
      return Left(contentDir.error);
    }

    try {
      final parser = ContentParser(
        config: config,
      );

      final content = parser.parse(contentDir.value);
      return Right(
          data.copyWith(pages: content.getPages(), content: content, shortcodeTemplates: shortcodeTemplates.toList()));
    } on BuildError catch (e) {
      return Left(e);
    }
  }
}
