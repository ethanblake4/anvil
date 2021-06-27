import 'package:anvil/anvil.dart';
import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/build_step/build_step.dart';
import 'package:anvil/src/content/build_page.dart';
import 'package:anvil/src/util/either.dart';

class BuildAliases extends BuildStep {
  BuildAliases({required Config config}) : super(config: config);

  late Map<String, Object?> data;

  @override
  Either<BuildError, BuildData> run(BuildData data) {
    final pages = data.pages;
    if (pages == null) {
      return const Left(BuildError('Pages must be built before building aliases'));
    }

    try {
      for (final page in pages) {
        if (page.aliases.isNotEmpty) {
          for (final alias in page.aliases) {
            final _alias = alias as String;
            final path = _alias.startsWith('/') ? _alias.substring(1) : _alias;
            final redirectPage = RedirectPage(
              path: path,
              destinationUrl: page.getPublicUrl(config, isServe: data.serve),
            );
            buildPage(config, data, redirectPage);
          }
        }
      }

      return Right(data);
    } on BuildError catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(BuildError('Failed to parse data'));
    }
  }
}
