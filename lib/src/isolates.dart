import 'dart:async';
import 'dart:isolate';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:io' show Directory;
import 'package:path/path.dart' as path;

final libraryPath = path.join(Directory.current.path, 'authority.dll');

typedef LoadDocNative = Uint8 Function(Pointer<Utf8>);
typedef LoadDoc = int Function(Pointer<Utf8>);
typedef ValidateNative = Bool Function(Uint8);
typedef Validate = bool Function(int);

class RDA {
  final Future<SendPort> futureSendPort = _helperIsolateSendPort;
  SendPort? helperIsolateSendPort;

  Future<void> init() async {
    await futureSendPort.then(
      ((value) => helperIsolateSendPort = value),
      onError: (err) => print(err),
    );
  }

  Future<int> load(String path) async {
    final int requestId = _nextRequestId++;
    final _LoadRequest request = _LoadRequest(requestId, path);
    final Completer<int> completer = Completer<int>();
    _Requests[requestId] = completer;
    helperIsolateSendPort?.send(request);
    return completer.future;
  }

  Future<bool> valid(int index) async {
    final int requestId = _nextRequestId++;
    final _ValidRequest request = _ValidRequest(requestId, index);
    final Completer<bool> completer = Completer<bool>();
    _Requests[requestId] = completer;
    helperIsolateSendPort?.send(request);
    return completer.future;
  }
}

class _LoadRequest {
  final int id;
  final String path;
  const _LoadRequest(this.id, this.path);
}

class _LoadResponse {
  final int id;
  final int result;
  const _LoadResponse(this.id, this.result);
}

class _ValidRequest {
  final int id;
  final int idx;
  const _ValidRequest(this.id, this.idx);
}

class _ValidResponse {
  final int id;
  final bool result;
  const _ValidResponse(this.id, this.result);
}

int _nextRequestId = 0;

/// Mapping from [_SumRequest] `id`s to the completers corresponding to the correct future of the pending request.
final Map<int, Completer> _Requests = <int, Completer>{};

/// The SendPort belonging to the helper isolate.
Future<SendPort> _helperIsolateSendPort = () async {
  // The helper isolate is going to send us back a SendPort, which we want to
  // wait for.
  final Completer<SendPort> sendCompleter = Completer<SendPort>();

  // Receive port on the main isolate to receive messages from the helper.
  // We receive two types of messages:
  // 1. A port to send messages on.
  // 2. Responses to requests we sent.
  final ReceivePort receivePort =
      ReceivePort()..listen((dynamic data) {
        if (data is SendPort) {
          // The helper isolate sent us the port on which we can sent it requests.
          sendCompleter.complete(data);
          return;
        }
        if (data is _LoadResponse || data is _ValidResponse) {
          // The helper isolate sent us a response to a request we sent.
          final Completer completer = _Requests[data.id]!;
          _Requests.remove(data.id);
          completer.complete(data.result);
          return;
        }
        throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
      });

  // Start the helper isolate.
  await Isolate.spawn((SendPort sendPort) async {
    final DynamicLibrary _dylib = DynamicLibrary.open(libraryPath);
    final LoadDoc _loadDoc = _dylib.lookupFunction<LoadDocNative, LoadDoc>(
      'load_doc',
    );
    final Validate _validate = _dylib.lookupFunction<ValidateNative, Validate>(
      'valid',
    );

    final ReceivePort helperReceivePort =
        ReceivePort()..listen((dynamic data) {
          // On the helper isolate listen to requests and respond to them.
          if (data is _LoadRequest) {
            final p = data.path.toNativeUtf8();
            final int result = _loadDoc(p);
            malloc.free(p);
            final _LoadResponse response = _LoadResponse(data.id, result);
            sendPort.send(response);
            return;
          } else if (data is _ValidRequest) {
            final bool result = _validate(data.idx);
            final _ValidResponse response = _ValidResponse(data.id, result);
            sendPort.send(response);
            return;
          }
          throw UnsupportedError(
            'Unsupported message type: ${data.runtimeType}',
          );
        });

    // Send the port to the main isolate on which we can receive requests.
    sendPort.send(helperReceivePort.sendPort);
  }, receivePort.sendPort);

  // Wait until the helper isolate has sent us back the SendPort on which we
  // can start sending requests.
  return sendCompleter.future;
}();
