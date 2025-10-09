import 'package:test/test.dart';
import '../lib/authority.dart';
import 'dart:io' show Directory;
import 'package:path/path.dart' as path;

void main() async {
  final rda = RDA();
  await rda.init();
  final examplePath = path.join(
    Directory.current.path,
    'test',
    'SRNSW_example.xml',
  );
  final doc = await rda.load(examplePath);
  test('validate the doc', () async {
    final valid = await rda.valid(doc);
    expect(valid, true);
  });
  test('print the doc', () async {
    final str = await rda.asString(doc);
    expect(str.length, 11034);
  });
}
