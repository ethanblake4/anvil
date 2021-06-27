import 'package:anvil/src/config.dart';
import 'package:anvil/src/errors.dart';
import 'package:anvil/src/util/either.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:yaml/yaml.dart';

const fs = LocalFileSystem();

extension DirectoryExtension on Directory {
  /// If [Directory] already exists delete all its contents and create it again.
  Future<Directory> reset({bool recursive = true}) async {
    if (await exists()) {
      await delete(recursive: recursive);
    }
    return create(recursive: recursive);
  }
}

extension FileSystemEntityExtension on FileSystemEntity {
  /// Handle every possible FS entity.
  R? when<R>({
    R Function(File file)? file,
    R Function(Directory directory)? directory,
    R Function(Link link)? link,
  }) {
    if (fs.isFileSync(path)) {
      return file?.call(this as File);
    } else if (fs.isDirectorySync(path)) {
      return directory?.call(this as Directory);
    } else {
      return link?.call(this as Link);
    }
  }
}

Directory _getOrThrow(Directory directory) {
  if (directory.existsSync()) {
    return directory;
  }

  throw BuildError('Directory ${directory.path} does not exists');
}

/// Public directory contains generated static files suitable for publishing.
///
/// Config: `build.public_dir`
Future<Directory> getPublicDirectory(Config config) async {
  return _getOrThrow(
    fs.directory(config.build.publicDir),
  );
}

/// Content directory contains Markdown/HTML files.
///
/// Config: `build.content_dir`
Future<Either<BuildError, Directory>> getContentDirectory(Config config) async {
  final directory = fs.directory(config.build.contentDir);
  if (await directory.exists()) {
    return Right(directory);
  } else {
    return Left(BuildError('Directory ${directory.path} does not exists'));
  }
}

/// Templates folder contains Jinja templates for rendering Markdown files
/// inside content folder.
///
/// Config: `build.templates_dir`
Directory getTemplatesDirectory(Config config) {
  return _getOrThrow(
    fs.directory(config.build.templatesDir),
  );
}

/// Static folder contains files to be copied into public folder like CSS or JS.
///
/// Config: `build.static_dir`
Directory getStaticDirectory(Config config) {
  return _getOrThrow(
    fs.directory(config.build.staticDir),
  );
}

Directory getDataDirectory(Config config) {
  return _getOrThrow(
    fs.directory(config.build.dataDir),
  );
}

/// Returns content of `config.yaml` file or throws when the file does
/// not exists.
Future<Either<ConfigError, Config>> getConfig() async {
  if (await isProjectDirectory()) {
    final file = await _getConfigFile();
    final config = await file.readAsString();
    final yaml = loadYaml(config) as YamlMap;
    return Right(Config.fromYaml(yaml));
  }

  return const Left(
    ConfigError('Config file does not exist in current location'),
  );
}

Future<bool> isProjectDirectory() {
  return fs.file(kAnvilConfigFile).exists();
}

Future<File> _getConfigFile() async {
  return fs.file(kAnvilConfigFile).create();
}

const kAnvilConfigFile = 'anvil.yaml';
