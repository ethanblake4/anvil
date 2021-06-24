import 'package:file/file.dart';
import 'package:process_run/shell.dart' hide which;
import 'package:dcli/dcli.dart' hide Shell;

class GitUtil {
  GitUtil._();

  static bool? _isGitInstalled;

  static DateTime? getModified(File file) {
    if (which('git').notfound) {
      return null;
    }
    if (!isGitDir()) {
      return null;
    }

    return _parseOutput('git log --follow --format=%aI -1 -- ${file.path}'
        .toList().join('\n'));
  }

  /// Get date when [file] was first tracked in git history.
  static DateTime? getCreated(File file) {
    if (!isGitInstalled() || !isGitDir()) {
      return null;
    }
    final result =
        'git log --diff-filter=A --follow --format=%aI -1 -- ${file.path}'
        .firstLine;

    if (result == null) {
      return null;
    }

    return _parseOutput(result);
  }

  static bool isGitInstalled() {
    if (_isGitInstalled != null) {
      return _isGitInstalled!;
    } else {
      return _isGitInstalled = which('git').found;
    }
  }

  static DateTime? _parseOutput(String output) {
    if (output.trim().isEmpty) {
      return null;
    } else {
      return DateTime.parse(output);
    }
  }

  /// Checks if current dir is git repository.
  ///
  /// The result value is cached after first invocation. However, when the users
  /// starts local server and then runs `git init` this will not update its
  /// result. We might change this in the future.
  static bool isGitDir() {
    try {
      return 'git rev-parse --is-inside-work-tree'.firstLine?.trim() == 'true';
    } catch (e) {
      return false;
    }
  }
}
