import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Minimal FFI to talk to mpv directly since media_kit 1.2.x doesn't expose setProperty yet.
typedef MPVSetPropertyString = Int32 Function(
    Pointer<Void> ctx, Pointer<Utf8> name, Pointer<Utf8> data);
typedef MPVSetPropertyStringDart = int Function(
    Pointer<Void> ctx, Pointer<Utf8> name, Pointer<Utf8> data);

// mpv_get_property_string returns a char* that must be freed with mpv_free
typedef MPVGetPropertyString = Pointer<Utf8> Function(
    Pointer<Void> ctx, Pointer<Utf8> name);
typedef MPVGetPropertyStringDart = Pointer<Utf8> Function(
    Pointer<Void> ctx, Pointer<Utf8> name);

typedef MPVFree = Void Function(Pointer<Void> data);
typedef MPVFreeDart = void Function(Pointer<Void> data);

class MpvHelper {
  static final DynamicLibrary _lib = _loadLib();

  static DynamicLibrary _loadLib() {
    try {
      if (Platform.isAndroid) return DynamicLibrary.process();
      return DynamicLibrary.open('libmpv.so.1');
    } catch (_) {
      try {
        if (Platform.isWindows) return DynamicLibrary.open('mpv-2.dll');
        return DynamicLibrary.open('libmpv.so');
      } catch (e) {
        // Last-ditch effort: try process() as many modern platforms link mpv statically or semi-statically
        try {
          return DynamicLibrary.process();
        } catch (_) {
          print('[MpvHelper] FATAL: Could not open libmpv on any path: $e');
          rethrow;
        }
      }
    }
  }

  static final MPVSetPropertyStringDart _setPropertyString =
      _lib.lookupFunction<MPVSetPropertyString, MPVSetPropertyStringDart>(
          'mpv_set_property_string');

  static final MPVGetPropertyStringDart _getPropertyString =
      _lib.lookupFunction<MPVGetPropertyString, MPVGetPropertyStringDart>(
          'mpv_get_property_string');

  static final MPVFreeDart _mpvFree =
      _lib.lookupFunction<MPVFree, MPVFreeDart>('mpv_free');

  static void setProperty(int handle, String name, String value) {
    try {
      final namePtr = name.toNativeUtf8();
      final valuePtr = value.toNativeUtf8();
      final context = Pointer<Void>.fromAddress(handle);

      final result = _setPropertyString(context, namePtr, valuePtr);
      if (result != 0) {
        print(
            '[MpvHelper] setProperty "$name" = "$value" returned error: $result');
      }

      malloc.free(namePtr);
      malloc.free(valuePtr);
    } catch (e) {
      print('[MpvHelper] Error setting property $name: $e');
    }
  }

  /// Read a property from mpv. Returns null if the property doesn't exist or on error.
  static String? getProperty(int handle, String name) {
    try {
      final namePtr = name.toNativeUtf8();
      final context = Pointer<Void>.fromAddress(handle);

      final resultPtr = _getPropertyString(context, namePtr);
      malloc.free(namePtr);

      if (resultPtr == nullptr) return null;

      final value = resultPtr.toDartString();
      _mpvFree(resultPtr.cast<Void>());
      return value;
    } catch (e) {
      print('[MpvHelper] Error getting property $name: $e');
      return null;
    }
  }
}
