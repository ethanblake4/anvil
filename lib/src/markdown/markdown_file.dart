import 'package:yaml/yaml.dart';

class ContentFile {
  ContentFile({
    required this.type,
    required this.metadata,
    required this.content,
  });

  final YamlMap metadata;

  final ContentFileType type;

  /// Unrendered content.
  final String content;
}

enum ContentFileType {
  markdown,
  html
}