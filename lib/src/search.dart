import 'dart:convert';

import 'package:anvil/anvil.dart';
import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/build_step/build_step.dart';
import 'package:anvil/src/config.dart';
import 'package:anvil/src/content/content.dart';
import 'package:anvil/src/log.dart';
import 'package:anvil/src/util/either.dart';
import 'package:anvil/src/utils.dart';

/// Build JSON search index for static search of your content.
///
/// This is still very elementary and only outputs page title & path. In the
/// future might be possible to search though the page content.
class BuildSearchIndex extends BuildStep {
  const BuildSearchIndex({
    required Config config
  }) : super(config: config);


  @override
  Either<BuildError, BuildData> run(BuildData data) {

    final pages = data.pages;

    if(pages == null) {
      return const Left(BuildError('Must build pages before building search index'));
    }

    final index = pages.where((e) => e.public).map((e) {
      return <String, dynamic>{
        'title': e.title,
        'url': e.getPublicUrl(config),
      };
    }).toList();

    final indexFilePath = Path.join(
      config.build.publicDir,
      'search_index.json',
    );

    final indexFile = fs.file(indexFilePath)..createSync()..writeAsStringSync(json.encode(index));
    log.debug('Search index generated');

    if (indexFile.lengthSync() >= 1000000) {
      log.warning('Search index file is over 1MB');
    }

    return Right(data);
  }
}

List<Map<String, dynamic>> createSearchIndex(
  Content content,
  Config config,
  BuildData data,
) {
  final list = <Map<String, dynamic>>[];

  content.when(
    config,
    data,
    page: (config, buildData, page) {
      final metadata = page.toMap();
      list.add(
        <String, dynamic>{
          'title': metadata['name'],
          'url': '${config.baseUrl}${metadata['path']}',
        },
      );
    },
    section: (config, buildData, section) {
      for (final element in section.children) {
        list.addAll(createSearchIndex(element, config, data));
      }
    },
  );

  return list;
}
