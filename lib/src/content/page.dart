import 'package:anvil/anvil.dart';
import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/config.dart';
import 'package:anvil/src/content/content.dart';
import 'package:anvil/src/content/section.dart';
import 'package:anvil/src/file_system.dart';
import 'package:anvil/src/git_util.dart';
import 'package:anvil/src/utils.dart';

/// [Page] is leaf node which cannot have other subpages.
class Page extends Content {
  Page({
    required this.path,
    this.content,
    this.contentType,
    this.metadata = const <String, dynamic>{},
  });

  @override
  late final String title = metadata['title'] as String? ?? Path.basename(path);

  /// Public pages are build into public folder. When [public] is false,
  /// the page is not build. It is still accessible in templates in both cases.
  late final bool public = metadata['public'] as bool? ?? true;

  late final List<dynamic> tags =
      metadata['tags'] as List<dynamic>? ?? <dynamic>[];

  late final bool jinja = metadata['jinja'] as bool? ?? false;

  late List<dynamic> aliases =
      metadata['aliases'] as List<dynamic>? ?? <dynamic>[];

  DateTime? get date {
    final _date = metadata['date'] as String?;
    return _date != null ? DateTime.parse(_date) : null;
  }

  DateTime? getUpdated(Config config) {
    final _updated = metadata['updated'] as String?;

    if (_updated != null) {
      return DateTime.parse(_updated);
    } else {
      // TODO: Git value may be cached after obtaining.
      final _gitModified = GitUtil.getModified(
        fs.file(Path.join(config.build.contentDir, path)),
      );
      return _gitModified ?? date;
    }
  }

  @override
  final String path;

  final String? content;

  final ContentFileType? contentType;

  final Map<String, dynamic> metadata;

  bool get isIndex {
    final name = Path.basenameWithoutExtension(path);
    return name == 'index' || name == '_index';
  }

  /// Get final build path for this [Page].
  ///
  /// Index file is kept as is, only file extension is changed to HTML.
  /// For regular page is created a subdirectory with `index.html` file.
  ///
  /// Example:
  ///   content/post.md   ->  public/post/index.html
  ///   content/index.md  ->  public/index.html
  String getBuildPath(Config config) {
    final basename = Path.basenameWithoutExtension(path);
    final dirName = Path.dirname(path);

    if (isIndex) {
      // Index file may be named `index` or `_index`.
      // Underscore needs to be removed.
      final name = basename.startsWith('_') ? basename.substring(1) : basename;
      return Path.normalize(
        Path.join(
          config.build.publicDir,
          dirName,
          '$name.html',
        ),
      );
    } else {
      return Path.normalize(
        Path.join(
          config.build.publicDir,
          dirName,
          basename,
          'index.html',
        ),
      );
    }
  }

  String getPublicUrl(Config config, {bool isServe = false}) {
    final baseUrl = config.baseUrl.endsWith('/')
        ? config.baseUrl.substring(0, config.baseUrl.length - 1)
        : config.baseUrl;

    return getBuildPath(config)
        .replaceFirst(
          config.build.publicDir,
          isServe ? 'http://127.0.0.1:${config.serve.port}' : baseUrl,
        )
        .replaceFirst('index.html', '');
  }

  @override
  Map<String, Object?> toMap() {
    // TODO: [metadata] should be merged into the same map.
    return {
      'title': title,
      'path': path.replaceFirst('.md', '/').replaceFirst('.html', '/'),
      'content': content,
      'contentType': contentType.toString(),
      'metadata': metadata,
    };
  }

  @override
  R? when<R>(Config config, BuildData buildData, {
    R Function(Config config, BuildData buildData, Section section)? section,
    R Function(Config config, BuildData buildData, Page page)? page,
  }) {
    return page?.call(config, buildData, this);
  }

  @override
  String toString() => 'Page{path: $path, metadata: $metadata}';

  @override
  List<Page> getPages() => public ? [this] : [];
}