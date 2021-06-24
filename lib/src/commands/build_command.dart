import 'dart:async';
import 'dart:convert';

import 'package:anvil/anvil.dart';
import 'package:anvil/src/styles/styles_builder.dart';
import 'package:args/command_runner.dart';
import 'package:anvil/src/build/content_parser.dart';
import 'package:anvil/src/commands/serve_command.dart';
import 'package:anvil/src/config.dart';
import 'package:anvil/src/content/content.dart';
import 'package:anvil/src/content/page.dart';
import 'package:anvil/src/content/redirect_page.dart';
import 'package:anvil/src/content/section.dart';
import 'package:anvil/src/data.dart';
import 'package:anvil/src/errors.dart';
import 'package:anvil/src/file_system.dart';
import 'package:anvil/src/log.dart';
import 'package:anvil/src/markdown/footnote_syntax.dart';
import 'package:anvil/src/search.dart';
import 'package:anvil/src/sitemap_builder.dart';
import 'package:anvil/src/taxonomy.dart';
import 'package:anvil/src/util/either.dart';
import 'package:anvil/src/util/maybe.dart';
import 'package:anvil/src/utils.dart';
import 'package:file/file.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:jinja/jinja.dart' as jinja;
import 'package:markdown/markdown.dart';

class BuildCommand extends Command<int> {
  BuildCommand(this._config) {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Show more logs.',
      defaultsTo: false,
      negatable: false,
    );
  }

  final Config? _config;

  @override
  final name = 'build';

  @override
  final description = 'Build static files.';

  final _stopwatch = Stopwatch();

  bool isServe = false;

  late Map<String, Object?> data;

  /// Reload script is included when build is triggered using [ServeCommand].
  ///
  /// This needs to generate new instance on each access. HTML library probably
  /// works with references and mutates the node after usage. Therefore, when
  /// settings this field as `late final`, it will be inserted into DOM only
  /// once and subsequent uses fail.
  html_dom.DocumentFragment get script {
    return html_parser.parseFragment(
      '<script src="http://127.0.0.1:${_config!.serve.port}/reload.js"></script>',
    );
  }

  @override
  FutureOr<int> run() async {
    if(_config == null) {
      log.error('No $kAnvilConfigFile present in the current directory');
      return 1;
    }
    final result = await build(_config!);
    return result.when(
      () => 0,
      (value) {
        log.error(value);
        return 1;
      },
    );
  }

  Future<Maybe<BuildError>> build(
    Config config, {
    bool isServe = false,
  }) async {
    log.info('Building');
    _stopwatch.start();
    this.isServe = isServe;

    final contentDir = await getContentDirectory(config);
    if (contentDir.isError) {
      return Just(contentDir.error);
    }

    final content = await _parseContent(config, contentDir.value);
    if (content.isError) {
      return Just(content.error);
    }

    final pages = content.value.getPages();
    final tags = _buildTaxonomy(config, pages);
    data = await parseDataTree(config);
    data['tags'] = tags;

    await _buildAliases(config, pages);

    try {
      await _generateContent(config, content.value);
    } on BuildError catch (e) {
      return Just(e);
    }

    await _copyStaticFiles(config);

    log.debug('Static');

    await SitemapBuilder(
      config: config,
      pages: pages,
    ).build();

    StylesBuilder(config: config)
      .build();

    if (config.build.generateSearchIndex) {
      await _generateSearchIndex(config, pages);
    }

    _stopwatch.stop();
    log.info(
      'Build done in ${_stopwatch.elapsedMilliseconds}ms '
      '(${pages.length} pages)',
    );
    _stopwatch.reset();
    return const Nothing();
  }

  Future<Either<BuildError, Content>> _parseContent(
    Config config,
    Directory contentDir,
  ) async {
    try {
      final parser = ContentParser(
        config: config,
      );
      final content = await parser.parse(contentDir);
      return Right(content);
    } on BuildError catch (e) {
      return Left(e);
    }
  }

  /// Generate static files from content tree.
  Future<void> _generateContent(Config config, Content content) async {
    try {
      await content.when(
        config,
        section: _buildSection,
        page: _buildPage,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _buildSection(Config config, Section section) async {
    if (section.index != null) {
      final children = section.children.map((e) => e.toMap()).toList();
      final pages = section.children
          .whereType<Page>()
          .map((content) => content.toMap())
          .toList();

      final sections = section.children
          .whereType<Section>()
          .map((content) => content.toMap())
          .toList();

      await _buildPage(
        config,
        section.index!,
        extraData: <String, Object?>{
          'children': children,
          'pages': pages,
          'sections': sections,
        },
      );
    }

    try {
      for (final child in section.children) {
        await child.when(
          config,
          section: _buildSection,
          page: _buildPage,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Processes content in following order: Jinja -> shortcodes -> markdown.
  Future<void> _buildPage(
    Config config,
    Page page, {
    Map<String, Object?> extraData = const <String, Object>{},
  }) async {
    // log.debug('Build: $page');

    // Abort on non-public pages (i.e. data only page).
    if (!page.public) {
      log.debug('Page ${page.path} is not public');
      return;
    }

    final template = await _getTemplate(page, config);
    final baseUrl = config.getBaseUrl(isServe: isServe);
    final metadata = <String, Object?>{
      'title': page.title,
      'site': config.toMap()..set('baseUrl', baseUrl),
      'template': template!.path,
      'data': data,
    }
      ..addAll(page.metadata)
      ..addAll(extraData);

    var content = page.content ?? '';

    if (page.jinja) {
      try {
        content = config.environment
            .fromString(page.content ?? '')
            .renderMap(metadata);
      } catch (e) {
        _abortBuild(BuildError(e.toString(), '  Fix file ${page.path}'));
      }
    }

    if (page.contentType == ContentFileType.markdown) {
      final renderedMarkdownContent = markdownToHtml(
        content,
        extensionSet: ExtensionSet.gitHubWeb,
        blockSyntaxes: [FootnoteSyntax()],
        inlineSyntaxes: [FootnoteReferenceSyntax()],
      );

      metadata['content'] = renderedMarkdownContent;
    } else {
      metadata['content'] = content;
    }

    var output = template.renderMap(metadata);

    if (isServe) {
      final parsedHtml = html_parser.parse(output);
      if (parsedHtml.body != null) {
        parsedHtml.body!.nodes.add(script);
        output = parsedHtml.outerHtml;
      } else {
        log.warning('Could not include reload script into ${page.path}');
      }
    }
    final path = page.getBuildPath(config);
    final file = await fs.file(path).create(recursive: true);
    await file.writeAsString(output);
  }

  /// Move all files from static folder into public folder.
  Future<void> _copyStaticFiles(Config config) async {
    try {
      final staticDir = await getStaticDirectory(config);

      final staticContent = await staticDir.list(recursive: true).toList();
      final directories = staticContent.whereType<Directory>();
      final files = staticContent.whereType<File>();

      for (final directory in directories) {
        final path = directory.path.replaceFirst(
          config.build.staticDir,
          config.build.publicDir,
        );
        await fs.directory(path).create(recursive: true);
      }

      for (final file in files) {
        await file.copy(
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
  }

  /// Get template to render given [page]. If there is a `template` field in
  /// page front-matter it is used. Otherwise default template will used.
  Future<jinja.Template?> _getTemplate(
    Page page,
    Config config,
  ) async {
    // Template set in front matter has precedence.
    var templateName = page.metadata['template'] as String?;

    if (templateName == null) {
      throw BuildError(
        'Must provide a template name for ${page.path}.',
      );
    }

    final path = Path.join(config.build.templatesDir, templateName);
    final file = fs.file(path);

    if (!await file.exists()) {
      throw BuildError(
        "Template '$templateName' used in '${page.path}' does not exist.",
      );
    }

    try {
      return config.environment.getTemplate(templateName);
    } on ArgumentError catch (e) {
      _abortBuild(BuildError(e.toString()));
      return null;
    }
  }

  Future<void> _generateSearchIndex(Config config, List<Page> pages) async {
    final index = SearchIndexBuilder(
      config: config,
      pages: pages.where((element) => element.public).toList(),
    ).build();

    final indexFilePath = Path.join(
      config.build.publicDir,
      'search_index.json',
    );

    final indexFile = await fs.file(indexFilePath).create();
    await indexFile.writeAsString(json.encode(index));
    log.debug('Search index generated');

    final size = await indexFile.length();
    if (size >= 1000000) {
      log.warning('Search index file is over 1MB');
    }
  }

  List<Map<String, dynamic>> _buildTaxonomy(Config config, List<Page> pages) {
    final tags = <String, List<Page>>{};
    for (final page in pages) {
      for (final tag in page.tags) {
        tags[tag as String] ??= [];
        tags[tag]!.add(page);
      }
    }

    final result = List.generate(tags.length, (index) {
      final key = tags.keys.elementAt(index);
      return Tag(
        name: key,
        pages: tags[key]!,
      ).toMap(config);
    });

    log.debug('Tags: ${result.map((e) => '${e['name']}').toList()}');
    return result;
  }

  Future<void> _buildAliases(Config config, List<Page> pages) async {
    for (final page in pages) {
      if (page.aliases.isNotEmpty) {
        for (final alias in page.aliases) {
          final _alias = alias as String;
          final path = _alias.startsWith('/') ? _alias.substring(1) : _alias;
          final redirectPage = RedirectPage(
            path: path,
            destinationUrl: page.getPublicUrl(config, isServe: isServe),
          );
          await _buildPage(config, redirectPage);
        }
      }
    }
  }

  void _abortBuild(BlakeError error) {
    log.error(error, help: error.help);
  }
}

extension MapExtension<K, V> on Map<K, V> {
  void set(K key, V value) {
    this[key] = value;
  }
}
