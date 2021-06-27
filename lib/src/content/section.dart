import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/config.dart';
import 'package:anvil/src/content/content.dart';
import 'package:anvil/src/content/page.dart';

/// [Section] is node with other subsections or pages.
class Section extends Content {
  Section({
    this.index,
    required this.path,
    this.children = const [],
  });

  @override
  final String path;

  final Page? index;

  /// [Page] or [Section] content.
  final List<Content> children;

  @override
  Map<String, Object?> toMap() {
    final pages =
        children.whereType<Page>().map((content) => content.toMap()).toList();

    final sections = children
        .whereType<Section>()
        .map((content) => content.toMap())
        .toList();

    return {
      'title': title,
      'path': path,
      'pages': pages,
      'sections': sections,
    };
  }

  @override
  R? when<R>(Config config, BuildData buildData, {
    R Function(Config config, BuildData buildData, Section section)? section,
    R Function(Config config, BuildData buildData, Page page)? page,
  }) {
    return section?.call(config, buildData, this);
  }

  @override
  String toString() {
    return 'Section{path: $path, index: $index, children: $children}';
  }

  @override
  List<Page> getPages() {
    final list = <Page>[];

    if (index != null) {
      list.add(index!);
    }

    for (final child in children) {
      list.addAll(child.getPages());
    }
    return list;
  }
}
