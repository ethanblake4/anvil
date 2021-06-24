import 'dart:async';
import 'dart:io';

import 'package:anvil/src/file_system.dart';
import 'package:anvil/src/log.dart';
import 'package:anvil/src/utils.dart';
import 'package:mime/mime.dart';

/// Local web server used for `anvil serve` command.
///
/// This server binds to [address] and starts both HTTP and WebSocket (for
/// live-reload) handler.
class LocalServer {
  LocalServer(
    this.path, {
    this.address = '127.0.0.1',
    this.port = 4040,
    this.websocketPort = 4041,
    required this.onReload,
  });

  /// Directory where should the [LocalServer] be started.
  final String path;

  /// Server address.
  final String address;

  final int port;

  final int websocketPort;

  final Stream<void> onReload;

  late HttpServer httpServer;

  Future<void> start() async {
    final directoryServer = DirectoryServer(path: path);

    try {
      // ignore: unawaited_futures
      _startWebsocket();
    } catch (e) {
      log.error('Failed to start WebSocket server.');
      return;
    }

    httpServer = await HttpServer.bind(address, port);
    log.info('Server started on http://$address:$port');

    await httpServer.forEach(directoryServer.serve);
  }

  Future<void> _startWebsocket() async {
    StreamSubscription<void>? _sub;
    final websocket = await HttpServer.bind(address, websocketPort);
    websocket.transform(WebSocketTransformer()).listen(
      (WebSocket socket) async {
        await _sub?.cancel();
        _sub = onReload.listen((event) {
          socket.add('reload_event');
        });
      },
    );
  }
}

/// Serves local directory with given [path] as a web server.
class DirectoryServer {
  DirectoryServer({
    required this.path,
  });

  /// Base path. All files are looked-up within this path subtree.
  final String path;

  Future<void> serve(HttpRequest request) async {
    String? path;

    final uri = request.requestedUri.path.substring(1);
    if (uri.isEmpty || uri.endsWith('/')) {
      path = Path.join(this.path, uri, 'index.html');
    } else {
      path = Path.join(this.path, uri);
    }

    final file = fs.file(path);
    final response = request.response;

    if (!await file.exists()) {
      // TODO: Return 404 page when files doesn't exists.
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }

    final extension = Path.extension(path);
    final mime = _getMimeType(extension);
    response.headers.set('Content-Type', '$mime; charset=UTF-8');
    await response.addStream(file.openRead());
    await response.close();
  }

  String _getMimeType(String path) {
    return lookupMimeType(path) ?? 'text/plain';
  }
}
