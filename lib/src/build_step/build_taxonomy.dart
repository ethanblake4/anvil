import 'package:anvil/anvil.dart';
import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/build_step/build_step.dart';
import 'package:anvil/src/log.dart';
import 'package:anvil/src/util/either.dart';

class BuildTaxonomy extends BuildStep {
  BuildTaxonomy({required Config config}) : super(config: config);

  late Map<String, Object?> data;

  @override
  Either<BuildError, BuildData> run(BuildData data) {
    final pages = data.pages;
    if (pages == null) {
      return const Left(BuildError('Pages must be built before building taxonomy'));
    }

    final tags = <String, List<Page>>{};
    for (final page in pages) {
      for (final tag in page.tags) {
        tags[tag as String] ??= [];
        tags[tag]!.add(page);
      }
    }

    final result = List.generate(tags.length, (index) {
      final key = tags.keys.elementAt(index);
      return Tag(
        name: key,
        pages: tags[key]!,
      ).toMap(config);
    });

    log.debug('Tags: ${result.map((e) => '${e['name']}').toList()}');
    return Right(data.copyWith(tags: result));
  }
}
