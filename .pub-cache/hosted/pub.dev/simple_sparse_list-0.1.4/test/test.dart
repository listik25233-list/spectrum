import 'dart:convert';

import 'package:simple_sparse_list/ranges_helper.dart';
import 'package:simple_sparse_list/simple_sparse_list.dart';
import 'package:test/test.dart';

void main() {
  _combineRanges();
  _testNormalizeRanges();
  _testSortRanges();
  _testSparseList();
}

void _combineRanges() {
  test('Combine ranges', () {
    Set<int> combineSets(Set<int> x, Set<int> y) {
      final result = <int>{...x, ...y};
      return result;
    }

    bool compareSets(Set<int> x, Set<int> y) {
      if (x.length != y.length) {
        return false;
      }

      final list1 = x.toList();
      final list2 = y.toList();
      for (var i = 0; i < list1.length; i++) {
        if (list1[i] != list2[i]) {
          return false;
        }
      }

      return true;
    }

    (Map<int, Set<int>>, List<(int, int, Set<int>)>) pattern2map(
        String encoded) {
      final values = <int, Set<int>>{};
      final list = <(int, int, Set<int>)>[];
      final lines = const LineSplitter().convert(encoded);
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final start = line.indexOf('-');
        final count = line.codeUnits.where((e) => e != 32).length;
        final end = start + count - 1;
        final value = (start, end, {i});
        for (var j = start; j <= end; j++) {
          (values[j] ??= {}).add(i);
        }

        list.add(value);
      }

      return (values, list);
    }

    Map<int, Set<int>> list2map(List<(int, int, Set<int>)> list) {
      final values = <int, Set<int>>{};
      for (final element in list) {
        final start = element.$1;
        final end = element.$2;
        final value = element.$3;
        for (var i = start; i <= end; i++) {
          (values[i] ??= {}).addAll(value);
        }
      }

      return values;
    }

    const maxLevel = 2;
    const mark = '-';
    List<String> generate(int level) {
      const rangeLen = 5;
      final result = <String>[];
      final next = level > 0 ? generate(level - 1) : <String>[];
      for (var pos = 0; pos < (rangeLen + maxLevel * 2); pos++) {
        for (var len = 1; len <= rangeLen; len++) {
          final current = ' ' * pos + mark * len;
          if (next.isEmpty) {
            result.add(current);
          } else {
            for (final element in next) {
              final pattern = '$current\n$element';
              result.add(pattern);
            }
          }
        }
      }

      return result;
    }

    final patterns = generate(maxLevel);
    for (var i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final lines = const LineSplitter().convert(pattern);
      lines.sort((a, b) {
        final i = a.indexOf(mark, 0) - b.indexOf(mark, 0);
        if (i != 0) {
          return i;
        }

        return a.lastIndexOf(mark) - b.lastIndexOf(mark);
      });

      patterns[i] = lines.join('\n');
    }

    for (var i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final data = pattern2map(pattern);
      final r1 = data.$2;
      final m1 = data.$1;
      final r2 = combineRanges(r1, combine: combineSets, compare: compareSets);
      final m2 = list2map(r2);
      expect(m2.ss, m1.ss, reason: pattern);
      var lastEnd = -1;
      for (final element in r2) {
        expect(element.$2 > lastEnd, true,
            reason:
                'The last end value ($lastEnd) is not greater than the previous end value: $element\n$pattern');
        lastEnd = element.$2;
      }
    }
  });
}

void _testNormalizeRanges() {
  test('Normalize ranges', () {
    {
      final r1 = [(0, 0)];
      final r2 = normalizeRanges(r1);
      final r3 = [(0, 0)];
      expect(r2, r3);
    }
    {
      final r1 = [(0, 2), (0, 0)];
      final r2 = normalizeRanges(r1);
      final r3 = [(0, 2)];
      expect(r2, r3);
    }
    {
      final r1 = [(3, 5), (0, 0), (0, 2)];
      final r2 = normalizeRanges(r1);
      final r3 = [(0, 5)];
      expect(r2, r3);
    }
    {
      final r1 = [(4, 10), (11, 15), (0, 5)];
      final r2 = normalizeRanges(r1);
      final r3 = [(0, 15)];
      expect(r2, r3);
    }
    {
      final r1 = [(0, 1), (2, 3), (4, 5), (6, 7)];
      final r2 = normalizeRanges(r1);
      final r3 = [(0, 7)];
      expect(r2, r3);
    }
    {
      final r1 = [(5, 10), (0, 1), (5, 11), (15, 20), (6, 7)];
      final r2 = normalizeRanges(r1);
      final r3 = [(0, 1), (5, 11), (15, 20)];
      expect(r2, r3);
    }
    {
      final r1 = [(5, 10), (0, 1), (5, 11), (15, 20), (4, 7)];
      final r2 = normalizeRanges(r1);
      final r3 = [(0, 1), (4, 11), (15, 20)];
      expect(r2, r3);
    }
    {
      final r1 = [(1, 3), (2, 4), (3, 5), (4, 6)];
      final r2 = normalizeRanges(r1);
      final r3 = [(1, 6)];
      expect(r2, r3);
    }
  });
}

void _testSortRanges() {
  test('Sort ranges', () {
    {
      final r1 = [
        (0, 0),
      ];
      final r2 = sortRanges(r1);
      final r3 = [
        (0, 0),
      ];
      expect(r2, r3);
    }
    {
      final r1 = [
        (1, 15),
        (0, 0),
        (1, 5),
      ];
      final r2 = sortRanges(r1);
      final r3 = [
        (0, 0),
        (1, 5),
        (1, 15),
      ];
      expect(r2, r3);
    }
    {
      final r1 = [(5, 10), (0, 1), (5, 11), (15, 20), (4, 7)];
      final r2 = sortRanges(r1);
      final r3 = [
        (0, 1),
        (4, 7),
        (5, 10),
        (5, 11),
        (15, 20),
      ];
      expect(r2, r3);
    }
    {
      final r1 = [(5, 10), (0, 1), (5, 11), (15, 20), (6, 7)];
      final r2 = sortRanges(r1);
      final r3 = [
        (0, 1),
        (5, 10),
        (5, 11),
        (6, 7),
        (15, 20),
      ];
      expect(r2, r3);
    }
  });
}

void _testSparseList() {
  void iterate<E>(List<(int, int, E)> data, E defaultValue) {
    final length = data.isEmpty ? 0 : data.last.$2 + 1;
    final list = List<E>.filled(length, defaultValue);
    for (final element in data) {
      final start = element.$1;
      final end = element.$2;
      final value = element.$3;
      for (var i = start; i <= end; i++) {
        list[i] = value;
      }
    }

    final sparseList = SparseList(data, defaultValue);
    expect(list.length, list.length, reason: 'List length');
    for (var i = 0; i < sparseList.length; i++) {
      final actual = sparseList[i];
      final expected = list[i];
      expect(actual, expected, reason: 'Value at index $i');
    }
  }

  test('SparseList', () {
    {
      final data = <(int, int, String?)>[];
      iterate(data, null);
    }
    {
      final data = <(int, int, int?)>[];
      for (var i = 0; i < 100; i++) {
        data.add((i, i, i));
      }

      iterate(data, null);
    }
    {
      final data = <(int, int, int?)>[];
      for (var i = 0; i < 100; i++) {
        final start = i * 10;
        data.add((start, start + 5, i));
      }

      iterate(data, null);
    }
    {
      final data = [
        (1, 0, null),
      ];
      expect(() => SparseList(data, null), throwsA(isA<ArgumentError>()));
    }
    {
      final data = [
        (0, 10, null),
        (5, 15, null),
      ];
      expect(() => SparseList(data, null), throwsA(isA<ArgumentError>()));
    }
  });
}

extension on Map<int, Set<int>> {
  String get ss {
    return entries.map((e) {
      final values = e.value.toList();
      values.sort();
      return '${e.key}: {${values.join(', ')}}';
    }).join(', ');
  }
}
