import 'package:anvil/anvil.dart';
import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/build/shortcode_renderer.dart';
import 'package:anvil/src/log.dart';
import 'package:anvil/src/markdown/footnote_syntax.dart';
import 'package:anvil/src/utils.dart';
import 'package:jinja/jinja.dart' as jinja;
import 'package:html/parser.dart' as html_parser;
import 'package:markdown/markdown.dart';


/// Processes content in following order: Jinja -> shortcodes -> markdown.
void buildPage(
    Config config,
    BuildData buildData,
    Page page, {
      Map<String, Object?> extraData = const <String, Object>{},
    }) {
  // log.debug('Build: $page');

  // Abort on non-public pages (i.e. data only page).
  if (!page.public) {
    log.debug('Page ${page.path} is not public');
    return;
  }

  final template = _getTemplate(page, config);
  final baseUrl = config.getBaseUrl(isServe: buildData.serve);
  final metadata = <String, Object?>{
    'title': page.title,
    'site': config.toMap()
      ..['baseUrl'] = baseUrl,
    'template': template!.path,
    'data': buildData.data,
  }..addAll(page.metadata)..addAll(extraData);

  var content = page.content ?? '';

  if (page.jinja) {
    try {
      content = config.environment
          .fromString(page.content ?? '')
          .renderMap(metadata);
    } catch (e) {
      log.error(e.toString(), help: '  Fix file ${page.path}');
    }
  }

  final renderedShortcodeContent = ShortcodeRenderer(
    shortcodeTemplates: buildData.shortcodeTemplates!,
    environment: config.environment,
  ).render(content);

  if (page.contentType == ContentFileType.markdown) {

    final renderedMarkdownContent = markdownToHtml(
      renderedShortcodeContent,
      extensionSet: ExtensionSet.gitHubWeb,
      blockSyntaxes: [FootnoteSyntax()],
      inlineSyntaxes: [FootnoteReferenceSyntax()],
    );

    metadata['content'] = renderedMarkdownContent;
  } else {
    metadata['content'] = renderedShortcodeContent;
  }

  var output = template.renderMap(metadata);

  if (buildData.serve) {
    final parsedHtml = html_parser.parse(output);
    if (parsedHtml.body != null) {
      final reloadScript = html_parser.parseFragment(
        '<script src="http://127.0.0.1:${config.serve.port}/reload.js"></script>',
      );
      parsedHtml.body!.nodes.add(reloadScript);
      output = parsedHtml.outerHtml;
    } else {
      log.warning('Could not include reload script into ${page.path}');
    }
  }
  final path = page.getBuildPath(config);
  fs.file(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(output);
}

/// Get template to render given [page]. If there is a `template` field in
/// page front-matter it is used. Otherwise default template will used.
jinja.Template? _getTemplate(
    Page page,
    Config config,
    ) {
  // Template set in front matter has precedence.
  var templateName = page.metadata['template'] as String?;

  if (templateName == null) {
    throw BuildError(
      'Must provide a template name for ${page.path}.',
    );
  }

  final path = Path.join(config.build.templatesDir, templateName);
  final file = fs.file(path);

  if (!file.existsSync()) {
    throw BuildError(
      "Template '$templateName' used in '${page.path}' does not exist.",
    );
  }

  return config.environment.getTemplate(templateName);

}