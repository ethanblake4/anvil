import 'package:anvil/anvil.dart';
import 'package:anvil/src/log.dart';
import 'package:anvil/src/shortcode.dart';
import 'package:anvil/src/template/environment.dart';

/// Replace every shortcode inside text file with its value.
///
/// To render an `input` call [ShortcodeRenderer.render] method.
class ShortcodeRenderer {
  ShortcodeRenderer({
    required this.environment,
    required this.shortcodeTemplates,
  });

  final CustomEnvironment environment;
  final List<ShortcodeTemplate> shortcodeTemplates;

  final parser = ShortcodeParser();

  String render(String input) {
    var _result = input;

    for (final shortcode in shortcodeTemplates) {
      /*
       Inline shortcodes
      */

      final pattern = RegExp('\\{{2}< ${shortcode.name}(.)* />\\}{2}');
      final inlineMatches = pattern.allMatches(input);

      for (final match in inlineMatches) {
        final variables = _parseInlineShortcode(
          input.substring(match.start, match.end),
        );

        final output = shortcode.render(
          environment: environment,
          values: variables.getValues(),
        );

        _result = _result.replaceFirst(
          input.substring(match.start, match.end),
          output,
        );
      }

      /*
       Block shortcodes
      */

      final ptn = RegExp(
          r'\{\{< ' + shortcode.name + r'[^\}]* >\}\}([\s\S]*?)\{\{< \/' + shortcode.name + r' >\}\}');

      final matches = ptn.allMatches(input);

      for(final match in matches) {
        final m = input.substring(match.start, match.end);
        final gr0 = match.group(1)!;
        final id = m.indexOf(gr0);
        final variables = _parseBodyShortcode(m, m.substring(id, id + gr0.length));

        final output = shortcode.render(
          environment: environment,
          values: variables.getValues(),
        );

        _result = _result.replaceFirst(
          input.substring(match.start, match.end),
          output,
        );
      }
    }
    return _result;
  }

  // TODO: Parser might throw an error.
  Shortcode _parseInlineShortcode(String input) {
    final shortcode = parser.parseInline(input);
    return shortcode;
  }

  Shortcode _parseBodyShortcode(String input, String body) {
    final _shortcode = parser.parseBlock(input);
    final b = _shortcode.arguments.firstWhere((element) => element.name == 'body');
    b.value = render(body);
    return _shortcode;
  }
}

