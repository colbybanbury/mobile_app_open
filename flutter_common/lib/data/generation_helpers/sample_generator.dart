import 'package:uuid/uuid.dart';

import 'package:mlperfbench_common/data/build_info/build_info.dart';
import 'package:mlperfbench_common/data/environment/env_android.dart';
import 'package:mlperfbench_common/data/environment/env_ios.dart';
import 'package:mlperfbench_common/data/environment/env_windows.dart';
import 'package:mlperfbench_common/data/environment/environment_info.dart';
import 'package:mlperfbench_common/data/extended_result.dart';
import 'package:mlperfbench_common/data/meta_info.dart';
import 'package:mlperfbench_common/data/results/backend_info.dart';
import 'package:mlperfbench_common/data/results/backend_settings.dart';
import 'package:mlperfbench_common/data/results/backend_settings_extra.dart';
import 'package:mlperfbench_common/data/results/benchmark_result.dart';
import 'package:mlperfbench_common/data/results/dataset_info.dart';

/// Generates sample data.
///
/// Generated data doesn't correspond to real values that could be obtained on some device.
/// It isn't even guaranteed to be logically consistent.
class SampleGenerator {
  BenchmarkRunResult get runResult => BenchmarkRunResult(
        throughput: const Throughput(value: 1234.45),
        accuracy: const Accuracy(
          normalized: 0.123,
          formatted: '12.3%',
        ),
        accuracy2: const Accuracy(
          normalized: 0.123,
          formatted: '12.3%',
        ),
        dataset: DatasetInfo(
          name: 'Imagenet classification validation set',
          type: DatasetTypeEnum.imagenet,
          dataPath: 'mlperf_datasets/imagenet/img',
          groundtruthPath: 'mlperf_datasets/imagenet/imagenet_val_full.txt',
        ),
        measuredDuration: 123.456,
        measuredSamples: 8,
        startDatetime: DateTime.now(),
        loadgenInfo: BenchmarkLoadgenInfo(
          duration: 10.6,
          validity: true,
        ),
      );

  BenchmarkExportResult get exportResult => BenchmarkExportResult(
        benchmarkId: 'id',
        benchmarkName: 'name',
        performanceRun: runResult,
        accuracyRun: runResult,
        minDuration: 10.5,
        minSamples: 8,
        backendSettings: BackendSettingsInfo(
          acceleratorCode: 'ane',
          acceleratorDesc: 'ANE',
          framework: 'TFLite',
          delegate: 'Core ML',
          modelPath: 'https://example.com/model.tflite',
          batchSize: 0,
          extraSettings: <BackendExtraSetting>[
            BackendExtraSetting(
              id: 'shards_num',
              name: 'Shards number',
              value: '2',
              valueName: '2',
            ),
          ],
        ),
        backendInfo: BackendReportedInfo(
          filename: 'libtflitebackend',
          vendorName: 'Google',
          backendName: 'TFLite',
          acceleratorName: 'ANE',
        ),
        loadgenScenario:
            BenchmarkExportResult.parseLoadgenScenario('SingleStream'),
      );

  EnvironmentInfo get envInfo => EnvironmentInfo(
        platform: EnvPlatform.android,
        value: EnvInfoValue(
          android: EnvAndroid(
            osVersion: '',
            modelCode: '',
            modelName: '',
            boardCode: '',
            manufacturer: '',
            procCpuinfoSocName: '',
            props: [
              EnvAndroidProp(
                type: AndroidPropType.socName,
                name: '',
                value: '',
              )
            ],
          ),
          ios: EnvIos(
            osVersion: '',
            modelCode: '',
            modelName: '',
            socName: '',
          ),
          windows: EnvWindows(
            osVersion: '',
            cpuFullName: '',
          ),
        ),
      );

  BuildInfo get buildInfo => BuildInfo(
        version: '1.0',
        buildNumber: '10qwe',
        buildDate: DateTime.now(),
        gitBranch: 'feature',
        gitCommit: 'as91230jr90qwe',
        gitDirtyFlag: false,
        devTestFlag: true,
        backendList: <String>[
          'libtflitebackend',
        ],
        officialReleaseFlag: false,
      );

  ExtendedResult get extendedResult => ExtendedResult(
        meta: ResultMetaInfo(
          creationDate: DateTime.now(),
          uploadDate: DateTime.now(),
          uuid: const Uuid().v4(),
        ),
        buildInfo: buildInfo,
        environmentInfo: envInfo,
        results: [exportResult, exportResult],
      );
}
