import 'package:anvil/src/config.dart';
import 'package:anvil/src/content/page.dart';
import 'package:anvil/src/file_system.dart';
import 'package:anvil/src/log.dart';
import 'package:anvil/src/utils.dart';
import 'package:xml/xml.dart';

class SitemapBuilder {
  const SitemapBuilder({
    required this.pages,
    required this.config,
  });

  final List<Page> pages;
  final Config config;

  Future<void> build() async {

    final builder = XmlBuilder();

    final nest = await _buildNodes();

    // ignore: cascade_invocations
    builder
      ..processing('xml', 'version="1.0" encoding="utf-8" standalone="yes"')
      ..element(
        'urlset',
        nest: nest,
        attributes: {
          'xmlns': 'http://www.sitemaps.org/schemas/sitemap/0.9',
          'xmlns:xhtml': 'http://www.w3.org/1999/xhtml',
        },
      );

    await _createFile(builder.buildDocument().toXmlString(pretty: true));
  }

  Future<Iterable<XmlNode>> _buildNodes() async {

    return pages.map((e) {

      final _updated = e.getUpdated(config);

      final url = e.getPublicUrl(config);

      final x =  XmlElement(
        XmlName('url'),
        [],
        [
          XmlElement(
            XmlName('loc'),
            [],
            [XmlText(url)],
          ),
          if (_updated != null)
            XmlElement(
              XmlName('lastmod'),
              [],
              [XmlText(_updated.toIso8601String())],
            )
        ],
      );

      return x;
    });
  }

  Future<void> _createFile(String content) async {
    final file = await fs
        .file(Path.join(config.build.publicDir, 'sitemap.xml'))
        .create(recursive: true);

    await file.writeAsString(content);
  }
}
