import 'dart:collection';

class SparseList<E> extends ListBase<E> {
  final List<(int, int, E)> _data = [];

  int _length = 0;

  final E defaultValue;

  SparseList(List<(int, int, E)> data, this.defaultValue, {int? length}) {
    _checkValidity(data);
    _data.addAll(_sort(data));
    if (_data.isNotEmpty) {
      _length = _data.last.$2 + 1;
    }

    if (length != null) {
      if (length < 0) {
        throw ArgumentError.value(
            length, 'length', 'Must be greater than or equal to 0');
      }

      if (length < _length) {
        throw ArgumentError.value(
            length, 'length', 'Must be not less than $_length');
      }

      _length = length;
    }

    _checkIntersection(_data);
  }

  @override
  int get length => _length;

  @override
  set length(int newLength) => throw UnsupportedError('set length');

  @override
  E operator [](int index) {
    final length = this.length;
    if (index < 0 || index >= length) {
      throw RangeError.index(index, this, 'index');
    }

    return _search(index);
  }

  @override
  void operator []=(int index, E value) => throw UnsupportedError('[]=');

  List<(int, int, E)> getGroups() => UnmodifiableListView(_data);

  void _checkIntersection(List<(int, int, E)> data) {
    if (data.length < 2) {
      return;
    }

    var prev = data.first;
    for (var i = 1; i < data.length; i++) {
      final curr = data[i];
      if (curr.$1 <= prev.$2) {
        throw ArgumentError(
            'Range (${curr.$1}, ${curr.$2}) intersects with range (${prev.$1}, ${prev.$2})');
      }

      prev = curr;
    }
  }

  void _checkValidity(List<(int, int, E)> data) {
    for (var i = 0; i < data.length; i++) {
      final range = data[i];
      final start = range.$1;
      final end = range.$2;
      if (start > end) {
        throw ArgumentError('Invalid range at index $i: ($start, $end)');
      }
    }
  }

  E _search(int value) {
    var left = 0;
    var right = _data.length;
    int middle;
    while (left < right) {
      middle = (left + right) >> 1;
      final element = _data[middle];
      if (value > element.$2) {
        left = middle + 1;
      } else if (value < element.$1) {
        right = middle;
      } else if (value >= element.$1 && value <= element.$2) {
        return element.$3;
      }
    }

    return defaultValue;
  }

  List<(int, int, E)> _sort(List<(int, int, E)> data) {
    data = data.toList();
    data.sort((a, b) {
      if (a.$1 != b.$1) {
        return a.$1.compareTo(b.$1);
      }

      return a.$2.compareTo(b.$2);
    });

    return data;
  }
}
