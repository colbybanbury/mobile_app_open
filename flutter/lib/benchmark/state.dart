import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'package:wakelock/wakelock.dart';

import 'package:mlperfbench/backend/bridge/isolate.dart';
import 'package:mlperfbench/backend/list.dart';
import 'package:mlperfbench/build_info.dart';
import 'package:mlperfbench/resources/config_manager.dart';
import 'package:mlperfbench/resources/resource_manager.dart';
import 'package:mlperfbench/resources/result_manager.dart';
import 'package:mlperfbench/resources/validation_helper.dart';
import 'package:mlperfbench/state/last_result_manager.dart';
import 'package:mlperfbench/state/task_runner.dart';
import 'package:mlperfbench/store.dart';
import 'benchmark.dart';

enum BenchmarkStateEnum {
  downloading,
  waiting,
  running,
  aborting,
  done,
}

class BenchmarkState extends ChangeNotifier {
  final Store _store;
  final BackendInfo backendInfo;
  final ResourceManager _resourceManager;
  final ConfigManager _configManager;
  final TaskRunner taskRunner;
  final LastResultManager lastResultManager;

  Object? error;
  StackTrace? stackTrace;

  bool taskConfigFailedToLoad = false;
  // null - downloading/waiting; false - running; true - done
  bool? _doneRunning;

  List<Benchmark> get benchmarks => _middle.benchmarks;

  late BenchmarkList _middle;

  BenchmarkStateEnum get state {
    if (!_resourceManager.done) return BenchmarkStateEnum.downloading;
    switch (_doneRunning) {
      case null:
        return BenchmarkStateEnum.waiting;
      case false:
        return taskRunner.aborting
            ? BenchmarkStateEnum.aborting
            : BenchmarkStateEnum.running;
      case true:
        return BenchmarkStateEnum.done;
    }
    throw StateError('unreachable');
  }

  ValidationHelper get validator {
    return ValidationHelper(
      resourceManager: _resourceManager,
      middle: _middle,
      selectedRunModes: taskRunner.selectedRunModes,
    );
  }

  BenchmarkState(
    this._store,
    this.backendInfo,
    this._resourceManager,
    this._configManager,
    this.taskRunner,
  ) : lastResultManager = LastResultManager(_store) {
    _resourceManager.setUpdateNotifier(notifyListeners);
    _configManager.setUpdateNotifier(onConfigChange);
    taskRunner.setUpdateNotifier(notifyListeners);
  }

  Future<void> clearCache() async {
    await _resourceManager.cacheManager.deleteLoadedResources([], 0);
    notifyListeners();
    try {
      await _configManager.setConfig(name: _store.chosenConfigurationName);
    } catch (e, trace) {
      print("can't load resources: $e");
      print(trace);
      error = e;
      stackTrace = trace;
      taskConfigFailedToLoad = true;
      notifyListeners();
    }
  }

  // Start loading resources in background.
  // Return type 'void' is intended, this function must not be awaited.
  void deferredLoadResources() async {
    try {
      await loadResources();
    } catch (e, trace) {
      print("can't load resources: $e");
      print(trace);
      error = e;
      stackTrace = trace;
      taskConfigFailedToLoad = true;
      notifyListeners();
    }
  }

  Future<void> loadResources() async {
    final newAppVersion =
        '${BuildInfoHelper.info.version}+${BuildInfoHelper.info.buildNumber}';
    var needToPurgeCache = _store.previousAppVersion != newAppVersion;
    _store.previousAppVersion = newAppVersion;

    await Wakelock.enable();
    print('start loading resources');
    await _resourceManager.handleResources(
      _middle.listResources(
        modes: [taskRunner.perfMode, taskRunner.accuracyMode],
        skipInactive: false,
      ),
      needToPurgeCache,
    );
    print('finished loading resources');
    error = null;
    stackTrace = null;
    taskConfigFailedToLoad = false;
    await Wakelock.disable();
  }

  static Future<BenchmarkState> create({
    required Store store,
    required BridgeIsolate bridgeIsolate,
    required BackendInfo backendInfo,
    required ResourceManager resourceManager,
    required ConfigManager configManager,
    required TaskRunner taskRunner,
  }) async {
    final result = BenchmarkState(
      store,
      backendInfo,
      resourceManager,
      configManager,
      taskRunner,
    );
    try {
      await result._configManager
          .setConfig(name: store.chosenConfigurationName);
    } catch (e, trace) {
      print("can't load resources: $e");
      print(trace);
      result.error = e;
      result.stackTrace = trace;
      result.taskConfigFailedToLoad = true;
    }

    return result;
  }

  void onConfigChange() {
    _store.chosenConfigurationName = _configManager.currentConfigName;
    error = null;
    stackTrace = null;
    taskConfigFailedToLoad = false;

    _middle = BenchmarkList(
      appConfig: _configManager.currentConfig,
      backendConfig: backendInfo.settings.benchmarkSetting,
      taskSelection: parseTaskSelection(_store.taskSelection),
    );
    restoreLastResult();
    deferredLoadResources();
  }

  static Map<String, bool> parseTaskSelection(String json) {
    Map<String, bool> result = {};
    if (json.isEmpty) {
      return result;
    }

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      for (var kv in map.entries) {
        result[kv.key] = kv.value as bool;
      }
    } catch (e, t) {
      print('task selection parse fail: $e');
      print(t);
    }
    return result;
  }

  Future<void> saveTaskSelection() async {
    _store.taskSelection = jsonEncode(_middle.selection);
  }

  Future<void> runBenchmarks() async {
    assert(_resourceManager.done, 'Resource manager is not done.');
    assert(_doneRunning != false, '_doneRunning is false');
    _store.previousExtendedResult = '';
    _doneRunning = false;

    // disable screen sleep when benchmarks is running
    await Wakelock.enable();

    final startTime = DateTime.now();
    final logDirName = startTime.toIso8601String().replaceAll(':', '-');
    final currentLogDir = '${_resourceManager.resourceDir}/logs/$logDirName';

    try {
      resetCurrentResults();
      lastResultManager.value =
          await taskRunner.runBenchmarks(_middle, currentLogDir);
      print('Benchmarks finished');

      _doneRunning = taskRunner.aborting ? null : true;
    } catch (e) {
      _doneRunning = null;
      rethrow;
    } finally {
      if (currentLogDir.isNotEmpty && !_store.keepLogs) {
        await Directory(currentLogDir).delete(recursive: true);
      }

      taskRunner.aborting = false;

      notifyListeners();

      await Wakelock.disable();
    }
  }

  void resetCurrentResults() {
    for (var b in _middle.benchmarks) {
      b.accuracyModeResult = null;
      b.performanceModeResult = null;
    }
  }

  void restoreLastResult() {
    if (_store.previousExtendedResult == '') {
      return;
    }

    try {
      lastResultManager.restore();
      ResultManager.restoreResults(
          lastResultManager.value!.results, benchmarks);
      _doneRunning = true;
      return;
    } catch (e, trace) {
      print('unable to restore previous extended result: $e');
      print(trace);
      error = e;
      stackTrace = trace;
      _store.previousExtendedResult = '';
      resetCurrentResults();
      _doneRunning = null;
    }
  }
}
