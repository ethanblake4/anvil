import 'package:anvil/anvil.dart';
import 'package:anvil/src/content/page.dart';
import 'package:anvil/src/content/section.dart';
import 'package:anvil/src/utils.dart';

/// [Content] symbolizes node in content tree. See [Page] or [Section] for
/// concrete implementation.
abstract class Content {
  String get title => Path.basename(path);

  String get path;

  List<Page> getPages();

  R? when<R>(Config config, {
    R Function(Config config, Section section)? section,
    R Function(Config config, Page page)? page,
  });

  Map<String, Object?> toMap();
}
