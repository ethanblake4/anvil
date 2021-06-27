import 'package:anvil/anvil.dart';
import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/content/page.dart';
import 'package:anvil/src/content/section.dart';
import 'package:anvil/src/utils.dart';

/// [Content] symbolizes node in content tree. See [Page] or [Section] for
/// concrete implementation.
abstract class Content {
  String get title => Path.basename(path);

  String get path;

  List<Page> getPages();

  R? when<R>(Config config, BuildData buildData, {
    R Function(Config config, BuildData buildData, Section section)? section,
    R Function(Config config, BuildData buildData, Page page)? page,
  });

  Map<String, Object?> toMap();
}
