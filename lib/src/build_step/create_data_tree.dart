import 'package:anvil/anvil.dart';
import 'package:anvil/src/build/build_data.dart';
import 'package:anvil/src/build_step/build_step.dart';
import 'package:anvil/src/util/either.dart';

class CreateDataTree extends BuildStep {
  CreateDataTree({required Config config}) : super(config: config);

  late Map<String, Object?> data;

  @override
  Either<BuildError, BuildData> run(BuildData data) {
    try {
      final tree = parseDataTree(config);
      tree['tags'] = data.tags;
      return Right(data.copyWith(data: tree));
    } on BuildError catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(BuildError('Failed to parse data'));
    }
  }
}
