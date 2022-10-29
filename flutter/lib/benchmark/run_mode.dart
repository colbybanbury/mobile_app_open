import 'package:mlperfbench/protos/mlperf_task.pb.dart' as pb;

class BenchmarkRunMode {
  static const _performanceModeString = 'PerformanceOnly';
  static const _accuracyModeString = 'AccuracyOnly';

  static const _perfLogSuffix = 'performance';
  static const _accuracyLogSuffix = 'accuracy';

  final String loadgenMode;
  final String logSuffix;
  final pb.OneDatasetConfig Function(pb.TaskConfig taskConfig) chooseDataset;

  BenchmarkRunMode._({
    required this.loadgenMode,
    required this.logSuffix,
    required this.chooseDataset,
  });

  static BenchmarkRunMode performance = BenchmarkRunMode._(
    loadgenMode: _performanceModeString,
    logSuffix: _perfLogSuffix,
    chooseDataset: (task) => task.datasets.lite,
  );
  static BenchmarkRunMode accuracy = BenchmarkRunMode._(
    loadgenMode: _accuracyModeString,
    logSuffix: _accuracyLogSuffix,
    chooseDataset: (task) => task.datasets.full,
  );

  static BenchmarkRunMode performanceTest = BenchmarkRunMode._(
    loadgenMode: _performanceModeString,
    logSuffix: _perfLogSuffix,
    chooseDataset: (task) => task.datasets.tiny,
  );
  static BenchmarkRunMode accuracyTest = BenchmarkRunMode._(
    loadgenMode: _accuracyModeString,
    logSuffix: _accuracyLogSuffix,
    chooseDataset: (task) => task.datasets.tiny,
  );

  @override
  String toString() {
    return logSuffix;
  }
}
