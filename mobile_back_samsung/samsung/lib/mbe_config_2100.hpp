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

#ifndef MBE_CONFIG_2100_H
#define MBE_CONFIG_2100_H

const std::string mbe2100_config = R"SETTINGS(
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
  accelerator: "npu"
  accelerator_desc: "npu"
  framework: "ENN"
  custom_setting {
    id: "i_type"
    value: "Uint8"
  }
  custom_setting {
    id: "o_type"
    value: "Float32"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v1_0/Samsung/ic.nnc"
  model_checksum: "955ef2ac3c134820eab901f3dac9f732"
  single_stream_expected_latency_ns: 900000
}
benchmark_setting {
  benchmark_id: "image_segmentation_v1"
  accelerator: "npu"
  accelerator_desc: "npu"
  framework: "ENN"
  custom_setting {
    id: "i_type"
    value: "Uint8"
  }
  custom_setting {
    id: "o_type"
    value: "Uint8"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v1_0/Samsung/is.nnc"
  model_checksum: "b501ed669da753b08a151639798af37e"
  single_stream_expected_latency_ns: 1000000
}
benchmark_setting {
  benchmark_id: "image_segmentation_v2"
  accelerator: "npu"
  accelerator_desc: "npu"
  framework: "ENN"
  custom_setting {
    id: "i_type"
    value: "Uint8"
  }
  custom_setting {
    id: "o_type"
    value: "Uint8"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v1_0/Samsung/sm_uint8.nnc"
  model_checksum: "483eee2df253ecc135a6e8701cc0c909"
  single_stream_expected_latency_ns: 1000000
}
benchmark_setting {
  benchmark_id: "super_resolution"
  accelerator: "samsung_npu"
  accelerator_desc: "NPU"
  framework: "ENN"
  custom_setting {
    id: "i_type"
    value: "Uint8"
  }
  custom_setting {
    id: "o_type"
    value: "Float32"
  }
  model_path: "local:///MLPerf_sideload/sr.nnc"
  model_checksum: "6e725dffed620377b9eff463e106e6dd"
  single_stream_expected_latency_ns: 1000000
}
benchmark_setting {
  benchmark_id: "object_detection"
  accelerator: "npu"
  accelerator_desc: "npu"
  framework: "ENN"
  custom_setting {
    id: "i_type"
    value: "Uint8"
  }
  custom_setting {
    id: "o_type"
    value: "Float32"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v1_0/Samsung/od.nnc"
  model_checksum: "a3c7b5e8d6b978c05807e8926584758c"
  single_stream_expected_latency_ns: 1000000
}
benchmark_setting {
  benchmark_id: "natural_language_processing"
  accelerator: "gpu"
  accelerator_desc: "gpu"
  framework: "ENN"
  custom_setting {
    id: "i_type"
    value: "Int32"
  }
  custom_setting {
    id: "o_type"
    value: "Float32"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v1_0/Samsung/lu.nnc"
  model_checksum: "215ee3b9224d15dc50b30d56fa7b7396"
  single_stream_expected_latency_ns: 1000000
}
benchmark_setting {
  benchmark_id: "image_classification_offline"
  accelerator: "npudsp"
  accelerator_desc: "npu"
  framework: "ENN"
  batch_size: 8192
  custom_setting {
    id: "i_type"
    value: "Uint8"
  }
  custom_setting {
    id: "o_type"
    value: "Float32"
  }
  model_path: "https://github.com/mlcommons/mobile_models/raw/main/v1_0/Samsung/ic_offline.nncgo"
  model_checksum: "c38acf6c66ca32c525c14ce25ead823a"
  single_stream_expected_latency_ns: 1000000
})SETTINGS";
#endif
