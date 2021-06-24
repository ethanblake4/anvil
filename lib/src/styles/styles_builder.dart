import 'package:anvil/src/config.dart';
import 'package:anvil/src/file_system.dart';
import 'package:anvil/src/utils.dart';
import 'package:sass/sass.dart' as sass;

class StylesBuilder {
  const StylesBuilder({
    required this.config,
  });

  final Config config;

  void build() {

    final importer = sass.FilesystemImporter(config.build.stylesDir);
    final mainStyle = Path.join(config.build.stylesDir, 'main.scss');

    final css = sass.compile(
        mainStyle,
        importers: [importer],
        style: sass.OutputStyle.compressed
    );

    _createFile(css);
  }

  void _createFile(String content) {
    fs
        .file(Path.join(config.build.publicDir, 'styles.css'))
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
  }
}
