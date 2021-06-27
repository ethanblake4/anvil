import 'package:anvil/src/content/content.dart';
import 'package:anvil/src/content/page.dart';
import 'package:anvil/src/shortcode.dart';

/// Contains data about the currently executing build operation
class BuildData {
  BuildData({
    this.pages,
    this.tags,
    this.data,
    this.content,
    this.shortcodeTemplates,
    required this.serve,
  });

  final List<Page>? pages;
  final List<Map<String, dynamic>>? tags;
  final Map<String, Object?>? data;
  final List<ShortcodeTemplate>? shortcodeTemplates;
  final Content? content;
  final bool serve;

  BuildData copyWith(
      {List<Page>? pages,
      List<Map<String, dynamic>>? tags,
      Map<String, Object?>? data,
      Content? content,
      List<ShortcodeTemplate>? shortcodeTemplates}) {
    return BuildData(
        pages: pages ?? this.pages,
        tags: tags ?? this.tags,
        data: data ?? this.data,
        content: content ?? this.content,
        shortcodeTemplates: shortcodeTemplates ?? this.shortcodeTemplates,
        serve: serve);
  }
}
