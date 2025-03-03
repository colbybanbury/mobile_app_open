/* Copyright 2019 The MLPerf Authors. All Rights Reserved.
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
#include "flutter/cpp/mlperf_driver.h"

#include <stdint.h>

#include <memory>
#include <string>
#include <vector>

#include "flutter/cpp/backend.h"
#include "flutter/cpp/dataset.h"
#include "flutter/cpp/utils.h"
#include "loadgen/loadgen.h"
#include "loadgen/query_sample_library.h"
#include "loadgen/system_under_test.h"
#include "loadgen/test_settings.h"

namespace mlperf {
namespace mobile {

void MlperfDriver::IssueQuery(
    const std::vector<::mlperf::QuerySample>& samples) {
  std::vector<::mlperf::QuerySampleResponse> responses;
  std::vector<std::vector<uint8_t>> response_data;

  if (scenario_ == "Offline") {
    for (int idx = 0; idx < samples.size(); idx += batch_) {
      std::vector<::mlperf::QuerySample> sample;
      for (int b = 0; b < batch_; b++) {
        int sample_index =
            idx + b < samples.size()
                ? idx + b
                : samples.size() - 1;  // add extra data for filling batch
        sample.emplace_back(samples.at(sample_index));
        std::vector<void*> inputs = dataset_->GetData(sample.back().index);
        backend_->SetInputs(inputs, b);
      }

      backend_->IssueQuery();

      for (int b = 0; b < batch_; b++) {
        if (idx + b == samples.size()) break;  // ignore extra data
        // Report to mlperf.
        std::vector<void*> outputs = backend_->GetPredictedOutputs(b);
        response_data.push_back(
            dataset_->ProcessOutput(sample[b].index, outputs));
        responses.push_back(
            {sample[b].id,
             reinterpret_cast<std::uintptr_t>(response_data[idx + b].data()),
             response_data[idx + b].size()});
      }
      backend_->FlushQueries();
      query_counter_ += batch_;
    }
  } else {
    for (int idx = 0; idx < samples.size(); ++idx) {
      ::mlperf::QuerySample sample = samples.at(idx);
      std::vector<void*> inputs = dataset_->GetData(sample.index);
      backend_->SetInputs(inputs);
      backend_->IssueQuery();

      // Report to mlperf.
      std::vector<void*> outputs = backend_->GetPredictedOutputs();
      response_data.push_back(dataset_->ProcessOutput(sample.index, outputs));
      responses.push_back(
          {sample.id,
           reinterpret_cast<std::uintptr_t>(response_data[idx].data()),
           response_data[idx].size()});
      backend_->FlushQueries();
      query_counter_ += 1;
    }
  }
  ::mlperf::QuerySamplesComplete(responses.data(), responses.size());
}

void MlperfDriver::RunMLPerfTest(const std::string& mode, int min_query_count,
                                 double min_duration, double max_duration,
                                 int single_stream_expected_latency_ns,
                                 const std::string& output_dir) {
  // Setting the mlperf configs.
  ::mlperf::TestSettings mlperf_settings;
  ::mlperf::LogSettings log_settings;
  log_settings.log_output.outdir = output_dir;
  log_settings.log_output.copy_summary_to_stdout = true;

  mlperf_settings.min_query_count = min_query_count;
  mlperf_settings.mode = Str2TestMode(mode);
  mlperf_settings.qsl_rng_seed = 10003631887983097364UL;
  mlperf_settings.sample_index_rng_seed = 17183018601990103738UL;
  mlperf_settings.schedule_rng_seed = 12134888396634371638UL;
  mlperf_settings.min_duration_ms =
      static_cast<uint64_t>(std::ceil(min_duration * 1000.0));
  // Note: max_duration_ms works only in SingleStream scenario.
  // See https://github.com/mlcommons/inference/issues/1397
  mlperf_settings.max_duration_ms =
      static_cast<uint64_t>(std::ceil(max_duration * 1000.0));

  if (scenario_ == "Offline") {
    mlperf_settings.scenario = ::mlperf::TestScenario::Offline;
  } else {
    // Run MLPerf in SingleStream mode by default.
    mlperf_settings.scenario = ::mlperf::TestScenario::SingleStream;
    mlperf_settings.single_stream_expected_latency_ns =
        single_stream_expected_latency_ns;
  }

  ::mlperf::StartTest(this, dataset_.get(), mlperf_settings, log_settings);
}

}  // namespace mobile
}  // namespace mlperf
