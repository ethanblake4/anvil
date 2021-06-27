import 'package:anvil/anvil.dart';
import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/build_step/build_step.dart';
import 'package:anvil/src/content/build_page.dart';
import 'package:anvil/src/content/build_section.dart';
import 'package:anvil/src/util/either.dart';

class BuildContent extends BuildStep {
  BuildContent({required Config config}) : super(config: config);

  @override
  Either<BuildError, BuildData> run(BuildData data) {

    final content = data.content;
    if (content == null) {
      return const Left(BuildError('Content must be parsed before build'));
    }

    content.when(
      config,
      data,
      section: buildSection,
      page: buildPage,
    );

    return Right(data);
  }
}
