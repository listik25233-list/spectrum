import 'package:simple_sparse_list/ranges_helper.dart';
import 'package:simple_sparse_list/simple_sparse_list.dart';

void main(List<String> args) {
  _test(32);
  _test(48);
  _test(73);
  _test(100);
  _test(320);
  _test(0x10ffff);

  const values = [
    (0, 0, {'A'}),
    (0, 2, {'B'}),
    (3, 4, {'B'}),
    (5, 8, {'C'}),
    (6, 7, {'D'}),
    (10, 14, {'E'}),
    (11, 12, {'E'}),
    (16, 17, {'F'}),
  ];

  final combined = combineRanges<Set<String>>(values, combine: (x, y) {
    return {...x, ...y};
  }, compare: (x, y) {
    if (x.length != y.length) {
      return false;
    }

    for (final element in y) {
      if (!x.contains(element)) {
        return false;
      }
    }

    return true;
  });

  print(values);
  print(combined);
}

final _data = [
  (48, 57, Letter.number),
  (65, 90, Letter.upperCase),
  (97, 122, Letter.lowerCase),
];

final _list = SparseList(_data, Letter.unknown, length: 0x10ffff + 1);

void _test(int c) {
  final kind = _list[c];
  print('$c: $kind');
}

enum Letter { lowerCase, number, unknown, upperCase }
