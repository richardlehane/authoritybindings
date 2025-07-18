import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:io' show Directory;
import 'package:path/path.dart' as path;

final libraryPath = path.join(Directory.current.path, 'authority.dll');
final examplePath = path.join(
  Directory.current.path,
  'test',
  'SRNSW_example.xml',
);

typedef LoadDocNative = Uint8 Function(Pointer<Utf8>);
typedef LoadDoc = int Function(Pointer<Utf8>);
typedef ValidateNative = Bool Function(Uint8);
typedef Validate = bool Function(int);
typedef TrueThatNative = Bool Function();
typedef TrueThat = bool Function();
typedef UnloadNative = Void Function();
typedef Unload = void Function();

void main() {
  print("starting");

  final DynamicLibrary _dylib = DynamicLibrary.open(libraryPath);
  final LoadDoc _loadDoc = _dylib.lookupFunction<LoadDocNative, LoadDoc>(
    'load_doc',
  );
  final Validate _validate = _dylib.lookupFunction<ValidateNative, Validate>(
    'valid',
  );

  final _unload = _dylib.lookupFunction<UnloadNative, Unload>('unload');

  final p = examplePath.toNativeUtf8(allocator: malloc);
  // final int result = _loadDoc(p);
  // print(result);

  // final bool valid = _validate(result);
  // print(valid);
  final int newresults = _loadDoc(p);
  print(newresults);
  //print(_validate(newresults));
  //malloc.free(p);
  //_unload();

  //_dylib.close();
  //return;
}
