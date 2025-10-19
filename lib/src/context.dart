import 'dart:typed_data';
import 'dart:convert';

List<String> AsContext(Uint8List list) {
  final int num = list.first;
  List<String> ret = List.filled(num, "");
  int index = 1;
  for (var i = 0; i < num; i++) {
    int l = list.elementAt(index);
    ret[i] = utf8.decode(list.sublist(index + 1, index + 1 + l));
    index += l + 1;
  }
  return ret;
}
