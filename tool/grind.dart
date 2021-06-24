// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io' as io;

import 'package:anvil/src/utils.dart';
import 'package:grinder/grinder.dart';

part 'compile.dart';
part 'docs.dart';

void main(List<String> args) => grind(args);

@Task()
void test() => TestRunner().testAsync();

/// Compile Blake into a native binary.
///
/// This script produces a binary and archive into `build` directory.
@Task('Compile native binary')
@Depends(test)
@Depends(clean)
Future<void> compile() async {
  print('Compiling...');

  final platform = Platform.fromIO();

  const buildDir = 'build';
  final binaryName = platform.when(
    mac: () => 'anvil',
    windows: () => 'anvil.exe',
    linux: () => 'anvil',
  );
  final outputPath = Path.join(buildDir, binaryName);

  await io.Directory(buildDir).create();
  final compileResult = await io.Process.run(
    'dart',
    ['compile', 'exe', 'bin/anvil.dart', '-o', outputPath],
  );

  const archiveExtension = '.zip';
  final archiveName = platform.when(
    mac: () => 'anvil-mac',
    windows: () => 'anvil-win',
    linux: () => 'anvil-linux',
  );

  final archiveResult = await io.Process.run(
    'tar',
    ['-czf', archiveName + archiveExtension, 'anvil'],
    workingDirectory: buildDir,
  );

  if (archiveResult.exitCode != 0) {
    print('Archive could not be created: ${archiveResult.stderr}');
  }

  print('Done ${compileResult.exitCode}');
}

/// Removed files from `build` directory.
@Task()
void clean() => defaultClean();
