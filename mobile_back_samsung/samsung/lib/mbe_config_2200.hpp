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

#ifndef MBE_CONFIG_2200_H
#define MBE_CONFIG_2200_H

const std::string mbe2200_config = R"SETTINGS(
benchmark_setting {
  benchmark_id: "image_classification"
  accelerator: "samsung_npu"
  accelerator_desc: "NPU"
  framework: "ENN"
  custom_setting {
    id: "preset"
    value: "1001"
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
    value: "false"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v2_0/Samsung/ic_single.nnc"
  model_checksum: "a49175f3f4f37f59780995cec540dbf2"
  single_stream_expected_latency_ns: 900000
}
benchmark_setting {
  benchmark_id: "image_segmentation_v2"
  accelerator: "samsung_npu"
  accelerator_desc: "NPU"
  framework: "ENN"
  custom_setting {
    id: "preset"
    value: "1004"
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
    value: "false"
  }
  custom_setting {
    id: "lazy_mode"
    value: "false"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v2_0/Samsung/sm_uint8.nnc"
  model_checksum: "f715f55818863f371336ad29ecba1183"
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
  benchmark_id: "object_detection"
  accelerator: "samsung_npu"
  accelerator_desc: "NPU"
  framework: "ENN"
  custom_setting {
    id: "preset"
    value: "1003"
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
    value: "false"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v2_0/Samsung/od.nnc"
  model_checksum: "6b34201b6696fa75311d0d43820e03d2"
  single_stream_expected_latency_ns: 1000000
}
benchmark_setting {
  benchmark_id: "natural_language_processing"
  accelerator: "gpu"
  accelerator_desc: "gpu"
  framework: "ENN"
  custom_setting {
    id: "preset"
    value: "1000"
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
    value: "false"
  }
  custom_setting {
    id: "lazy_mode"
    value: "false"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v2_0/Samsung/mobile_bert_gpu.nnc"
  model_checksum: "d98dfcc37ad33fa7081d6fbb5bc6ddd1"
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
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v2_0/Samsung/ic_offline.nnc"
  model_checksum: "8832370c770fa820dfde83e039e3243c"
  single_stream_expected_latency_ns: 1000000
})SETTINGS";
#endif
