import 'package:test/test.dart';
import '../lib/authority.dart';
import 'dart:io' show Directory;
import 'package:path/path.dart' as path;

void main() async {
  test('validate the doc', () async {
    final examplePath = path.join(
      Directory.current.path,
      'test',
      'SRNSW_example.xml',
    );
    final rda = RDA();
    await rda.init();
    final doc = await rda.load(examplePath);
    final valid = await rda.valid(doc);
    expect(valid, true);
    print(valid);
  });
}
