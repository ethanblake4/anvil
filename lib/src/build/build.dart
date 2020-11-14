import 'dart:async';
import 'dart:io';

import 'package:blake/src/build/build_config.dart';
import 'package:blake/src/build/content_tree.dart';
import 'package:blake/src/content/content.dart';
import 'package:blake/src/content/page.dart';
import 'package:blake/src/content/section.dart';
import 'package:blake/src/file_system.dart';
import 'package:blake/src/log.dart';
import 'package:mustache_template/mustache_template.dart';

/// Build static site
Future<int> build(BuildConfig config) async {
  log.info('Building content');
  final stopwatch = Stopwatch()..start();
  final contentDir = await getContentDirectory(config);

  Content tree;
  try {
    tree = await parseContentTree(contentDir);
  } catch (e) {
    log.severe('Build failed: Could not parse content tree');
    return 1;
  }

  log.debug('Files: $tree');

  await generateContent(tree, config);
  await copyStaticFiles(config);

  stopwatch.stop();
  log.info('Build done in ${stopwatch.elapsedMilliseconds}ms');
  return 0;
}

Future<void> generateContent(Content content, BuildConfig config) async {
  await content.when(
    section: (section) => _buildSection(section, config),
    page: (page) => _buildPage(page, config),
  );
}

Future<void> _buildSection(Section section, BuildConfig config) async {
  if (section.index != null) {
    await _buildIndexPage(
      section.index,
      config,
      children: section.children,
    );
  }

  for (var child in section.children) {
    await child.when(
      section: (section) => _buildSection(section, config),
      page: (page) => _buildPage(page, config),
    );
  }
}

Future<void> _buildPage(Page page, BuildConfig config) async {
  log.debug('Build: $page');

  final templatesDir = await getTemplatesDirectory(config);
  final template = await File(
    '${templatesDir.path}/page.mustache',
  ).readAsString();

  final mustache = Template(template);

  final output = mustache.renderString(
    <dynamic, dynamic>{
      'title': page.name,
      'content': page.content,
    },
  );

  final path = page.getCanonicalPath(config);

  final file = await File(path).create(recursive: true);
  await file.writeAsString(output);
}

Future<void> _buildIndexPage(
  Page page,
  BuildConfig config, {
  List<Content> children = const [],
}) async {
  log.debug('Build: $page (index)');

  final templatesDir = await getTemplatesDirectory(config);
  final template = await File(
    '${templatesDir.path}/section.mustache',
  ).readAsString();

  final mustache = Template(template);

  final output = mustache.renderString(
    <dynamic, dynamic>{
      'title': page.name,
      'content': page.content,
      'children': children.whereType<Page>().map((e) => e.toMap(config)),
    },
  );

  final path = page.getCanonicalPath(config);

  final file = await File(path).create(recursive: true);
  await file.writeAsString(output);
}

Future<void> copyStaticFiles(BuildConfig config) async {
  final staticDir = await getStaticDirectory(config);

  final staticContent = await staticDir.list(recursive: true).toList();
  final directories = staticContent.whereType<Directory>();
  final files = staticContent.whereType<File>();

  for (var directory in directories) {
    final path = directory.path.replaceFirst('static', config.buildFolder);
    await Directory(path).create(
      recursive: true,
    );
  }

  for (var file in files) {
    await file.copy(file.path.replaceFirst('static', config.buildFolder));
  }

  if (config.verbose) {
    log.info('Static files copied');
  }
}
