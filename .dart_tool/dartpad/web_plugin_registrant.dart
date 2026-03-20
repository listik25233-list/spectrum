// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:audio_session/audio_session_web.dart';
import 'package:connectivity_plus/src/connectivity_plus_web.dart';
import 'package:flutter_secure_storage_web/flutter_secure_storage_web.dart';
import 'package:flutter_web_auth_2/src/web.dart';
import 'package:url_launcher_web/url_launcher_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  AudioSessionWeb.registerWith(registrar);
  ConnectivityPlusWebPlugin.registerWith(registrar);
  FlutterSecureStorageWeb.registerWith(registrar);
  FlutterWebAuth2WebPlugin.registerWith(registrar);
  UrlLauncherPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
