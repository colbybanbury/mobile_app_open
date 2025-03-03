/* Copyright 2020-2023 Samsung System LSI. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
==============================================================================*/
#include <string>

#ifndef MBE_CONFIG_2300_H
#define MBE_CONFIG_2300_H

const std::string mbe2300_config = R"SETTINGS(
common_setting {
  id: "num_threads"
  name: "Number of threads"
  value {
    value: "4"
    name: "4 threads"
  }
}

benchmark_setting {
  benchmark_id: "image_classification"
  accelerator: "samsung_npu"
  accelerator_desc: "NPU"
  framework: "ENN"
  custom_setting {
    id: "preset"
    value: "1009"
  }
  custom_setting {
    id: "i_type"
    value: "Uint8"
  }
  custom_setting {
    id: "o_type"
    value: "Float32"
  }
  custom_setting {
    id: "extension"
    value: "true"
  }
  custom_setting {
    id: "lazy_mode"
    value: "true"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v2_1/Samsung/ic_single_fence.nnc"
  model_checksum: "a451da1f48b1fad01c17fb7a49e5822e"
  single_stream_expected_latency_ns: 500000
}

benchmark_setting {
  benchmark_id: "image_segmentation_v2"
  accelerator: "samsung_npu"
  accelerator_desc: "NPU"
  framework: "ENN"
  custom_setting {
    id: "preset"
    value: "1009"
  }
  custom_setting {
    id: "i_type"
    value: "Uint8"
  }
  custom_setting {
    id: "o_type"
    value: "Uint8"
  }
  custom_setting {
    id: "extension"
    value: "true"
  }
  custom_setting {
    id: "lazy_mode"
    value: "true"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v2_1/Samsung/sm_uint8_fence.nnc"
  model_checksum: "08fa7b354f82140a8863fed57c2d499b"
  single_stream_expected_latency_ns: 1000000
}

benchmark_setting {
  benchmark_id: "object_detection"
  accelerator: "samsung_npu"
  accelerator_desc: "NPU"
  framework: "ENN"
  custom_setting {
    id: "preset"
    value: "1009"
  }
  custom_setting {
    id: "i_type"
    value: "Uint8"
  }
  custom_setting {
    id: "o_type"
    value: "Float32"
  }
  custom_setting {
    id: "extension"
    value: "true"
  }
  custom_setting {
    id: "lazy_mode"
    value: "true"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v2_1/Samsung/od_fence.nnc"
  model_checksum: "8a7e1808446072545c990f3d219255c6"
  single_stream_expected_latency_ns: 1000000
}

benchmark_setting {
  benchmark_id: "super_resolution"
  accelerator: "samsung_npu"
  accelerator_desc: "NPU"
  framework: "ENN"
  custom_setting {
    id: "preset"
    value: "1002"
  }
  custom_setting {
    id: "i_type"
    value: "Uint8"
  }
  custom_setting {
    id: "o_type"
    value: "Float32"
  }
  custom_setting {
    id: "extension"
    value: "true"
  }
  custom_setting {
    id: "lazy_mode"
    value: "true"
  }
  model_path: "local:///MLPerf_sideload/sr.nnc"
  model_checksum: "6e725dffed620377b9eff463e106e6dd"
  single_stream_expected_latency_ns: 1000000
}

benchmark_setting {
  benchmark_id: "natural_language_processing"
  accelerator: "npu"
  accelerator_desc: "npu"
  framework: "ENN"
  custom_setting {
    id: "preset"
    value: "1009"
  }
  custom_setting {
    id: "i_type"
    value: "Int32"
  }
  custom_setting {
    id: "o_type"
    value: "Float32"
  }
  custom_setting {
    id: "extension"
    value: "true"
  }
  custom_setting {
    id: "lazy_mode"
    value: "true"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v2_1/Samsung/mobile_bert_fence.nnc"
  model_checksum: "5fb666b684a9bd0b68d497128b990137"
  single_stream_expected_latency_ns: 1000000
}

benchmark_setting {
  benchmark_id: "image_classification_offline"
  accelerator: "samsung_npu"
  accelerator_desc: "npu"
  framework: "ENN"
  batch_size: 8192
  custom_setting {
    id: "scenario"
    value: "offline"
  }
  custom_setting {
    id: "preset"
    value: "1002"
  }
  custom_setting {
    id: "i_type"
    value: "Uint8"
  }
  custom_setting {
    id: "o_type"
    value: "Float32"
  }
  custom_setting {
    id: "extension"
    value: "false"
  }
  custom_setting {
    id: "lazy_mode"
    value: "false"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v2_1/Samsung/ic_offline.nnc"
  model_checksum: "6885f281a3d7a7ec3549d629dff8c8ac"
  single_stream_expected_latency_ns: 1000000
})SETTINGS";
#endif
