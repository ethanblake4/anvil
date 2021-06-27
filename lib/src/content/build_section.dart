

import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/config.dart';
import 'package:anvil/src/content/page.dart';
import 'package:anvil/src/content/section.dart';

import 'build_page.dart';

void buildSection(
    Config config, BuildData buildData, Section section) {
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

    buildPage(
      config,
      buildData,
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
      child.when(
        config,
        buildData,
        section: buildSection,
        page: buildPage,
      );
    }
  } catch (e) {
    rethrow;
  }
}