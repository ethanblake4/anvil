import 'package:anvil/src/config.dart';
import 'package:anvil/src/content/content.dart';
import 'package:anvil/src/content/page.dart';
import 'package:anvil/src/content/section.dart';
import 'package:anvil/src/errors.dart';
import 'package:anvil/src/file_system.dart';
import 'package:anvil/src/git_util.dart';
import 'package:anvil/src/markdown/markdown_file.dart';
import 'package:anvil/src/utils.dart';
import 'package:file/file.dart';
import 'package:yaml/yaml.dart' as yaml;

final _delimiter = RegExp(r'(---)(\n|\r)?');

class ContentParser {
  const ContentParser({
    required this.config,
  });

  final Config config;

  /// Recursively parse file tree starting from [entity].
  Content parse(FileSystemEntity entity) {
    return entity.when(
      file: (file) {

        final extension = file.path.substring(file.path.lastIndexOf('.') + 1);
        final contentType = (extension == 'html')
            ? ContentFileType.html : ContentFileType.markdown;

        final content = file.readAsStringSync();
        final parsed = _parseFile(contentType, content);

        // Remove leading 'content/' part of the directory.
        final path = Path.normalize(file.path).replaceFirst(
          '${config.build.contentDir}/',
          '',
        );

        final metadata = Map<String, dynamic>.from(parsed.metadata);

        if (!metadata.containsKey('date')) {
          if (GitUtil.isGitInstalled()) {
            final date = GitUtil.getModified(file);
            if (date != null) {
              metadata['date'] = date.toIso8601String();
            }
          }
        }

        return Page(
          path: path,
          contentType: parsed.type,
          content: parsed.content,
          metadata: metadata,
        );
      },
      directory: (directory) {
        final children = directory.listSync().toList();

        final content = (children.map(parse)).toList();

        final index = content.where((e) => e is Page && e.isIndex);
        if (index.length > 1) {
          throw BuildError(
            'Only one index file can be provided: '
                '${index.map((e) => e.path).toList()}',
            "Use either 'index.md' or '_index.md' file, not both.",
          );
        }

        // Remove leading 'content/' part of the directory.
        final path = Path.normalize(directory.path).replaceFirst(
          '${config.build.contentDir}/',
          '',
        );

        final indexes = content
            .where((element) => element is Page && element.isIndex)
            .whereType<Page>();

        return Section(
          path: path,
          index: indexes.isEmpty ? null : indexes.first,
          children: content
              .where((element) => !(element is Page && element.isIndex))
              .toList(),
        );
      },
      link: (link) {
        throw UnimplementedError('Link file is not yet supported.');
      },
    )!;
  }

  ContentFile _parseFile(
      ContentFileType type,
      String fileContent) {
    if (_delimiter.allMatches(fileContent).length < 2 ||
        _delimiter.firstMatch(fileContent)!.start != 0) {
      throw const MissingFrontmatterError(
        'Front matter is invalid or missing.',
      );
    }

    final matches = _delimiter.allMatches(fileContent).toList();
    final rawMetadata = fileContent.substring(matches[0].start, matches[1].end);
    final metadata = rawMetadata.substring(3, rawMetadata.length - 4).trim();

    final m = yaml.loadYaml(metadata) as yaml.YamlMap?;

    final content = fileContent.substring(matches[1].end).trim();

    return ContentFile(
      type: type,
      content: content,
      metadata: m ?? yaml.YamlMap.wrap(<String, Object?>{}),
    );
  }
}

class MissingFrontmatterError extends BuildError {
  const MissingFrontmatterError(
    String message, [
    String? help,
  ]) : super(message, help);

  @override
  String get name => 'MissingFrontmatterError';
}