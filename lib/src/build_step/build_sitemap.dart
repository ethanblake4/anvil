import 'package:anvil/anvil.dart';
import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/build_step/build_step.dart';
import 'package:anvil/src/config.dart';
import 'package:anvil/src/content/page.dart';
import 'package:anvil/src/util/either.dart';
import 'package:xml/xml.dart';

class BuildSitemap extends BuildStep {
  const BuildSitemap({
    required Config config
  }) : super(config: config);

  @override
  Either<BuildError, BuildData> run(BuildData data) {
    try {
      final content = data.content;
      if (content == null) {
        return const Left(BuildError('Pages must be built before building sitemap'));
      }

      final nest = _buildNodes(content.getPages());

      final builder = XmlBuilder()
        ..processing('xml', 'version="1.0" encoding="utf-8" standalone="yes"')
        ..element(
          'urlset',
          nest: nest,
          attributes: {
            'xmlns': 'http://www.sitemaps.org/schemas/sitemap/0.9',
            'xmlns:xhtml': 'http://www.w3.org/1999/xhtml',
          },
        );

      createFile('sitemap.xml', builder.buildDocument().toXmlString(pretty: true));
    } on XmlException catch (e) {
      return Left(BuildError('Error building sitemap: ${e.message}'));
    } catch (e) {
      return const Left(BuildError('Error building sitemap'));
    }

    return Right(data);
  }

  Iterable<XmlNode> _buildNodes(List<Page> pages) => pages.map((e) {
        final _updated = e.getUpdated(config);
        final url = e.getPublicUrl(config);

        final x = XmlElement(
          XmlName('url'),
          [],
          [
            XmlElement(XmlName('loc'), [], [XmlText(url)]),
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
