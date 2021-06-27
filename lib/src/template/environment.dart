import 'dart:convert';

import 'package:jinja/jinja.dart';

final _shortcodeMatcher = RegExp(r'''({{<\s*\/?[^(}})]+\s*\/?>}})''');

final _codeblockMatcher = RegExp(r'''{% code (\w+?) %}\n([\s\S]*?)\n{% endcode %}''');

/// Custom Jinja environment to support shortcode syntax.
///
/// [CustomEnvironment] wraps every shortcode inside Markdown file with Jinja's
/// escape tags so they are skipped. Otherwise Jinja throws an error.
class CustomEnvironment extends Environment {
  CustomEnvironment({Loader? loader}) : super(loader: loader);

  @override
  Template fromString(String source, {String? path}) {
    source = source.replaceAllMapped(
        _codeblockMatcher,
        (match) =>
            '<pre><code class="language-${match[1]}">${htmlEscape.convert(match[2]!)}</code></pre>');
    source = source.replaceAllMapped(
      _shortcodeMatcher,
      (match) => '{% raw %}${match[1]}{% endraw %}',
    );
    return super.fromString(source, path: path);
  }
}
