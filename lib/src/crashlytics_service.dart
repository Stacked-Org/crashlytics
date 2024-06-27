import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:stacked/stacked_annotations.dart';

class CrashlyticsService implements InitializableDependency {
  late FirebaseCrashlytics _instance;

  @override
  Future<void> init() async {
    _instance = FirebaseCrashlytics.instance;
  }

  void recordFlutterErrorToCrashlytics(FlutterErrorDetails details) {
    try {
      _instance.recordFlutterError(details);
    } catch (e) {
      _catchOrThrow(e);
    }
  }

  Future setUserIdToCrashlytics({String? id}) async {
    try {
      if (id != null) await _instance.setUserIdentifier(id);
    } catch (e) {
      _catchOrThrow(e);
    }
  }

  Future logToCrashlytics(
    Level level,
    List<String> lines,
    StackTrace stacktrace, {
    required bool logwarnings,
  }) async {
    try {
      if (level == Level.error || level == Level.fatal) {
        await _instance.recordError(
          lines.join('\n'),
          stacktrace,
          printDetails: true,
          fatal: true,
        );
      }
      if (level == Level.warning && logwarnings) {
        await _instance.recordError(
          lines.join('\n'),
          stacktrace,
          printDetails: true,
        );
      }
      if (level == Level.info || level == Level.trace || level == Level.debug) {
        await _instance.log(lines.join('\n'));
      }
    } catch (exception) {
      _catchOrThrow(exception);
    }
  }

  Future setCustomKeysToTrack(String key, dynamic value) async {
    try {
      await _instance.setCustomKey(key, value);
    } catch (e) {
      _catchOrThrow(e);
    }
  }

  // Be very careful when you execute this code it will crash the app
  // So, be sure to remove it after usage
  void crashApp() {
    try {
      _instance.crash();
    } catch (e) {
      _catchOrThrow(e);
    }
  }

  void _catchOrThrow(dynamic exception) {
    final exceptionString = exception.toString();
    final isPluginConstantsException = exceptionString
        .contains("pluginConstants['isCrashlyticsCollectionEnabled']");

    if (!isPluginConstantsException) {
      throw exception;
    }
  }
}

class CrashlyticsOutput extends LogOutput {
  final bool logWarnings;
  CrashlyticsOutput({this.logWarnings = false});

  @override
  Future<void> output(OutputEvent event) async {
    try {
      final service = CrashlyticsService();
      await service.init();
      return service.logToCrashlytics(
        event.level,
        event.lines,
        StackTrace.current,
        logwarnings: logWarnings,
      );
    } catch (e) {
      if (kDebugMode) {
        print('CRASHLYTICS FAILED: $e');
      }
    }
  }
}
