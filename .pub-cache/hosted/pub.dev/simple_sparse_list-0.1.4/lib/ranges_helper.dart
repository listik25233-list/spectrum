/// Combines [ranges] of values ​​by calling the [combine] function, comparing
/// values ​​by calling the [compare] function.
///
/// Returns a new array with the combined values ​​sorted in ascending range
/// order.
List<(int, int, T)> combineRanges<T>(
  List<(int, int, T)> ranges, {
  required T Function(T x, T y) combine,
  required bool Function(T x, T y) compare,
}) {
  ranges = ranges.toList();
  if (ranges.isEmpty) {
    return ranges;
  }

  if (ranges.length == 1) {
    return ranges;
  }

  ranges.sort((a, b) {
    if (a.$1 != b.$1) {
      return a.$1.compareTo(b.$1);
    }

    return a.$2.compareTo(b.$2);
  });

  for (var i = 0; i < ranges.length; i++) {
    final range = ranges[i];
    final start = range.$1;
    final end = range.$2;
    if (start > end) {
      throw ArgumentError('Invalid range at index $i: ($start, $end)');
    }
  }

  int min(int x, int y) => x < y ? x : y;

  final buffer = [ranges.first];
  for (var i = 1; i < ranges.length; i++) {
    (int, int, T)? b = ranges[i];
    for (var j = 0; j < buffer.length && b != null; j++) {
      final a = buffer[j];

      bool compareAB() => compare(a.$3, b!.$3);

      T combineAB() => combine(a.$3, b!.$3);
      (int, int, T)? subB(int newStart) {
        if (newStart > b!.$2) {
          return null;
        }

        return (newStart, b.$2, b.$3);
      }

      //    ---
      // ---
      if (a.$1 > b.$2) {
        buffer.insert(j, b);
        b = null;
        break;
      }

      // ---
      //    ---
      if (a.$2 < b.$1) {
        continue;
      }

      // --
      //  --
      //   ^
      if (a.$1 < b.$1) {
        final precedingA = (a.$1, b.$1 - 1, a.$3);
        final shortenedA = (b.$1, a.$2, a.$3);
        buffer.insert(j, precedingA);
        buffer[j + 1] = shortenedA;
        continue;
      }

      // --
      // --
      //
      if (b.$1 == a.$1) {
        final end = min(b.$2, a.$2);
        final rest = a.$2 - b.$2;
        final equal = compareAB();
        if (equal) {
          final value = (a.$1, end, a.$3);
          buffer[j] = value;
        } else {
          final v = combineAB();
          final value = (a.$1, end, v);
          buffer[j] = value;
        }

        b = subB(end + 1);
        if (rest > 0) {
          final value = (end + 1, a.$2, a.$3);
          buffer.insert(j + 1, value);
        }

        continue;
      }
    }

    if (b != null) {
      buffer.add(b);
      b = null;
    }
  }

  var hasChanges = false;
  while (true) {
    final buffer2 = <(int, int, T)>[];
    hasChanges = false;
    var lastGood = 0;
    for (var i = lastGood; i < buffer.length; i++) {
      final curr = buffer[i];
      final next = i == buffer.length - 1 ? null : buffer[i + 1];
      if (next == null) {
        buffer2.add(curr);
        continue;
      }

      if (curr.$2 < next.$1 - 1) {
        lastGood = i;
        buffer2.add(curr);
        continue;
      }

      if (curr.$2 == next.$1 - 1) {
        final equal = compare(curr.$3, next.$3);
        if (equal) {
          hasChanges = true;
          // Merge
          buffer2.add((curr.$1, next.$2, curr.$3));
          i++;
          continue;
        }
      }

      if (curr.$1 == next.$1 && curr.$2 == next.$2) {
        hasChanges = true;
        final equal = compare(curr.$3, next.$3);
        if (equal) {
          // Remove
          buffer2.add(curr);
        } else {
          // Combine
          final v = combine(curr.$3, next.$3);
          buffer2.add((curr.$1, curr.$2, v));
        }

        i++;
        continue;
      }

      buffer2.add(curr);
    }

    buffer.clear();
    buffer.addAll(buffer2);
    if (!hasChanges) {
      break;
    }
  }

  return buffer;
}

/// Normalizes ranges by sorting and merging them.
///
/// Returns a new array with the merged values ​​sorted in ascending range order.
List<(int, int)> normalizeRanges(List<(int, int)> ranges) {
  if (ranges.isEmpty) {
    return ranges.toList();
  }

  for (var i = 0; i < ranges.length; i++) {
    final range = ranges[i];
    final start = range.$1;
    final end = range.$2;
    if (start > end) {
      throw ArgumentError('Invalid range at index $i: ($start, $end)');
    }
  }

  ranges = sortRanges(ranges);
  final result = <(int, int)>[];
  final first = ranges.first;
  result.add(ranges.first);
  var prevStart = first.$1;
  var prevEnd = first.$2;
  for (var i = 1; i < ranges.length; i++) {
    final curr = ranges[i];
    final start = curr.$1;
    final end = curr.$2;
    if (start <= prevEnd + 1) {
      prevEnd = prevEnd > end ? prevEnd : end;
      result[result.length - 1] = (prevStart, prevEnd);
    } else {
      prevStart = start;
      prevEnd = end;
      result.add((start, end));
    }
  }

  return result;
}

/// Sorts [ranges] in ascending order.
///
/// Returns a new array with ranges sorted in ascending order.
List<(int, int)> sortRanges(List<(int, int)> ranges) {
  final result = ranges.toList();
  if (result.isEmpty) {
    return result.toList();
  }

  result.sort((a, b) {
    if (a.$1 != b.$1) {
      return a.$1.compareTo(b.$1);
    }

    return a.$2.compareTo(b.$2);
  });

  return result;
}
