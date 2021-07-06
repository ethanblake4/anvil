import 'dart:convert';
import 'dart:math';

import 'package:jinja/jinja.dart';

final _shortcodeMatcher = RegExp(r'''({{<\s*\/?[^(}})]+\s*\/?>}})''');

final _codeblockMatcher = RegExp(r'''{% code ([\w_-]+?)(?:\((.*)\))? %}([\s\S]*?){% endcode %}''');

/// Custom Jinja environment to support shortcode syntax.
///
/// [CustomEnvironment] wraps every shortcode inside Markdown file with Jinja's
/// escape tags so they are skipped. Otherwise Jinja throws an error.
class CustomEnvironment extends Environment {
  CustomEnvironment({Loader? loader}) : super(loader: loader);

  @override
  Template fromString(String source, {String? path}) {
    source = source.replaceAllMapped(_codeblockMatcher, (match) {
      var lang = match[1]!.trim();
      final params = match[2]?.trim() ?? '';
      final content = match[3]!.trimRight();
      var out = '';
      var pre = '';
      var post = '';
      var lines = content.split('\n');
      final line0 = lines.firstWhere((l) => l.trim().isNotEmpty);
      final idlen = line0.length - line0.trimLeft().length;
      if (lines[0].isEmpty) {
        lines = lines.sublist(1);
      }
      final paramMap = Map.fromEntries(params.split(',').where((element) => element.isNotEmpty).map((e) {
        return MapEntry(e.split('=')[0], e.split('=')[1]);
      }));

      if (paramMap.isNotEmpty) {
        final classList =
            paramMap.entries.fold('', (String pv, el) => '$pv${pv.isNotEmpty ? ' ' : ''}${el.key}-${el.value}');
        pre += "<div class='$classList'>";
        post += '</div>';
      }

      if (lang == 'bash' || lang == 'bash-root') {
        for (final line in lines) {
          out += '<span style="user-select: none;">${lang == 'bash-root' ? '#' : '\$'} </span>'
              '<code class="language-bash">${htmlEscape.convert(line.substring(min(idlen, line.length)))}</code><br>\n';
        }
        return '$pre<pre>$out</pre>$post';
      }
      final output = lines.map((l) => htmlEscape.convert(l.substring(min(idlen, l.length)))).join('\n');
      return '$pre<pre><code class="language-${match[1]!.trim()}">$output</code></pre>$post';
    });
    source = source.replaceAllMapped(
      _shortcodeMatcher,
      (match) => '{% raw %}${match[1]}{% endraw %}',
    );
    return super.fromString(source, path: path);
  }
}
