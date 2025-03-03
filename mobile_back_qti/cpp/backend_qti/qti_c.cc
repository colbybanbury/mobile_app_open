/* Copyright (c) 2020-2023 Qualcomm Innovation Center, Inc. All rights reserved.

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

#include <fstream>
#include <unordered_map>

#include "allocator.h"
#include "cpuctrl.h"
#include "mlperf_helper.h"
#include "qti_backend_helper.h"
#include "qti_settings.h"
#include "soc_utility.h"
#include "tensorflow/core/platform/logging.h"
#include "tflite_c.h"
#ifdef DEBUG_FLAG
#include <chrono>
using namespace std::chrono;
#endif

#define xverstr(a) verstr(a)
#define verstr(a) #a

#ifndef SNPE_VERSION_STRING
#define SNPE_VERSION_STRING "default"
#endif

static QTIBackendHelper *backend_data_ = nullptr;

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

// Should return true if current hardware is supported.
bool mlperf_backend_matches_hardware(const char **not_allowed_message,
                                     const char **settings,
                                     const mlperf_device_info_t *device_info) {
  if (device_info && device_info->model && device_info->manufacturer) {
    LOG(INFO) << "QTI HW supported check: model: " << device_info->model
              << ", manufacturer: " << device_info->manufacturer;
  }

  std::ifstream in_file;
#ifdef __ANDROID__
  const char *native_lib_path = device_info->native_lib_path;
  std::stringstream adsp_lib_path;
  adsp_lib_path << native_lib_path << ";";
  adsp_lib_path << "/system/lib/rfsa/adsp;/system/vendor/lib/rfsa/adsp;/dsp";
  LOG(INFO) << "adsp_lib_path: " << adsp_lib_path.str();
  setenv("ADSP_LIBRARY_PATH", adsp_lib_path.str().c_str(), 1 /*override*/);
  std::stringstream ld_lib_path;
  ld_lib_path << native_lib_path << ";";
  ld_lib_path << "/system/vendor/lib64";
  LOG(INFO) << "ld_lib_path: " << ld_lib_path.str();
  setenv("LD_LIBRARY_PATH", ld_lib_path.str().c_str(), 1 /*override*/);
#endif

  *not_allowed_message = nullptr;
  bool isQSoC = Socs::isSnapDragon(device_info->manufacturer);
  LOG(INFO) << "Is QTI SOC: " << isQSoC;
  if (isQSoC) {
    return Socs::soc_settings(settings, not_allowed_message);
  }

  // It's not a QTI SOC, so set pbData to NULL
  *settings = nullptr;
  return false;
}

// Create a new backend and return the pointer to it.
mlperf_backend_ptr_t mlperf_backend_create(
    const char *model_path, mlperf_backend_configuration_t *configs,
    const char *native_lib_path) {
  if (backend_data_) {
    LOG(FATAL) << "Only one backend instance can be active at a time";
  }
  LOG(INFO) << "CONFIGS count = " << configs->count;
  for (int i = 0; i < configs->count; ++i) {
    LOG(INFO) << "configs->[" << configs->keys[i]
              << "] = " << configs->values[i];
  }
  backend_data_ = new QTIBackendHelper();
  QTIBackendHelper *backend_data = backend_data_;

  process_config(configs, backend_data);

  if (backend_data->bgLoad_) {
    CpuCtrl::startLoad(backend_data->loadOffTime_, backend_data->loadOnTime_);
  }

  if (backend_data->isTflite_) {
    CpuCtrl::highLatency();
    backend_data->tfliteBackend_ = tflite_backend_create(model_path, configs);
    backend_data->getBuffer_ = std_get_buffer;
    backend_data->releaseBuffer_ = std_release_buffer;
    return backend_data;
  }

  // use lowLatency cores for all snpe models
  CpuCtrl::lowLatency();

  // Set buffers to be used for snpe
  if (backend_data->useIonBuffers_) {
    backend_data->getBuffer_ = get_ion_buffer;
    backend_data->releaseBuffer_ = release_ion_buffer;
  } else {
    backend_data->getBuffer_ = std_get_buffer;
    backend_data->releaseBuffer_ = std_release_buffer;
  }

#ifdef __ANDROID__
  std::stringstream adsp_lib_path;
  adsp_lib_path << native_lib_path << ";";
  adsp_lib_path << "/system/lib/rfsa/adsp;/system/vendor/lib/rfsa/adsp;/dsp";
  LOG(INFO) << "lib_path: " << adsp_lib_path.str();
  setenv("ADSP_LIBRARY_PATH", adsp_lib_path.str().c_str(), 1 /*override*/);
#endif
  std::string snpe_version = xverstr(SNPE_VERSION_STRING);
  if (snpe_version.compare("default") != 0) {
    int dotPosition = snpe_version.find_last_of(".");
    snpe_version = snpe_version.substr(dotPosition + 1);
  }

  if (snpe_version.compare(backend_data->get_snpe_version()) != 0) {
    LOG(FATAL) << "Snpe libs modified. expected: " << snpe_version
               << " found: " << backend_data->get_snpe_version();
  }
  LOG(INFO) << "snpe_version: " << snpe_version;

  // set runtime config
  backend_data->set_runtime_config();
  // Use PSNPE or SNPE
  if (backend_data->useSnpe_) {
    backend_data->use_snpe(model_path);
  } else {
    backend_data->use_psnpe(model_path);
  }

  backend_data->queryCount_ = 0;

  backend_data->get_data_formats();
  backend_data->map_inputs();
  backend_data->map_outputs();

  LOG(INFO) << "SNPE build completed successfully";

  return backend_data;
}

// Return the name of the accelerator.
const char *mlperf_backend_accelerator_name(mlperf_backend_ptr_t backend_ptr) {
  QTIBackendHelper *backend_data = (QTIBackendHelper *)backend_ptr;
  return backend_data->acceleratorName_;
}

// Return the name of this backend.
const char *mlperf_backend_name(mlperf_backend_ptr_t backend_ptr) {
  QTIBackendHelper *backend_data = (QTIBackendHelper *)backend_ptr;
  return backend_data->name_;
}

// Return the vendor name of this backend
const char *mlperf_backend_vendor_name(mlperf_backend_ptr_t backend_ptr) {
  return "QTI";
}

// Destroy the backend pointer and its data.
void mlperf_backend_delete(mlperf_backend_ptr_t backend_ptr) {
  QTIBackendHelper *backend_data = (QTIBackendHelper *)backend_ptr;
  LOG(INFO) << "Deleting Backend";
  if (backend_data->bgLoad_) {
    CpuCtrl::stopLoad();
  }
  CpuCtrl::normalLatency();
  if (backend_data->isTflite_) {
    tflite_backend_delete(backend_data->tfliteBackend_);
  }
  delete backend_data;
  backend_data_ = nullptr;
}

// Run the inference for a sample.
mlperf_status_t mlperf_backend_issue_query(mlperf_backend_ptr_t backend_ptr) {
  mlperf_status_t ret = MLPERF_FAILURE;

#ifdef DEBUG_FLAG
  auto start = high_resolution_clock::now();
#endif
  QTIBackendHelper *backend_data = (QTIBackendHelper *)backend_ptr;
  if (backend_data->isTflite_) {
    return tflite_backend_issue_query(backend_data->tfliteBackend_);
  }

  ret = backend_data->execute();

#ifdef DEBUG_FLAG
  auto end = high_resolution_clock::now();
  auto duration = duration_cast<microseconds>(end - start);
  LOG(INFO) << "Query cnt: " << backend_data->queryCount_
            << "Inference Time(ms): " << duration.count();
#endif
  backend_data->queryCount_++;
  return ret;
}

// Flush the staged queries immediately.
mlperf_status_t mlperf_backend_flush_queries(mlperf_backend_ptr_t backend_ptr) {
  QTIBackendHelper *backend_data = (QTIBackendHelper *)backend_ptr;
  if (backend_data->isTflite_) {
    return tflite_backend_flush_queries(backend_data->tfliteBackend_);
  }
  return MLPERF_SUCCESS;
}

// Return the number of inputs of the model.
int32_t mlperf_backend_get_input_count(mlperf_backend_ptr_t backend_ptr) {
  QTIBackendHelper *backend_data = (QTIBackendHelper *)backend_ptr;
  if (backend_data->isTflite_) {
    return tflite_backend_get_input_count(backend_data->tfliteBackend_);
  }
  return backend_data->inputFormat_.size();
}

// Return the type of the ith input.
mlperf_data_t mlperf_backend_get_input_type(mlperf_backend_ptr_t backend_ptr,
                                            int32_t i) {
  QTIBackendHelper *backend_data = (QTIBackendHelper *)backend_ptr;
  if (backend_data->isTflite_) {
    return tflite_backend_get_input_type(backend_data->tfliteBackend_, i);
  }
  return backend_data->inputFormat_[i];
}

// Set the data for ith input.
mlperf_status_t mlperf_backend_set_input(mlperf_backend_ptr_t backend_ptr,
                                         int32_t batchIndex, int32_t i,
                                         void *data) {
  QTIBackendHelper *backend_data = (QTIBackendHelper *)backend_ptr;
  if (backend_data->isTflite_) {
    return tflite_backend_set_input(backend_data->tfliteBackend_, batchIndex, i,
                                    data);
  }
  // The inputs are in contiguous batches of backend_data->inputBatch_ inputs
  // If the value is a pad value for batched case then use the pointer to
  // its contiguous block
  void *batchedDataPtr = (backend_data->inputBatch_ > 1)
                             ? ChunkAllocator::GetBatchPtr(data)
                             : data;
  // if (batchedDataPtr != data) {
  //   LOG(INFO) << "TESTING: Using " << batchedDataPtr << " instead of " <<
  //   data;
  // }
  Snpe_IUserBuffer_SetBufferAddress(
      Snpe_UserBufferMap_GetUserBuffer_Ref(
          Snpe_UserBufferList_At_Ref(backend_data->inputMapListHandle_,
                                     batchIndex / backend_data->inputBatch_),
          Snpe_StringList_At(backend_data->networkInputTensorNamesHandle_, i)),
      batchedDataPtr);
  return MLPERF_SUCCESS;
}

// Return the number of outputs for the model.
int32_t mlperf_backend_get_output_count(mlperf_backend_ptr_t backend_ptr) {
  QTIBackendHelper *backend_data = (QTIBackendHelper *)backend_ptr;
  if (backend_data->isTflite_) {
    return tflite_backend_get_output_count(backend_data->tfliteBackend_);
  }
  return backend_data->outputFormat_.size();
}
// Return the type of ith output.
mlperf_data_t mlperf_backend_get_output_type(mlperf_backend_ptr_t backend_ptr,
                                             int32_t i) {
  QTIBackendHelper *backend_data = (QTIBackendHelper *)backend_ptr;
  if (backend_data->isTflite_) {
    return tflite_backend_get_output_type(backend_data->tfliteBackend_, i);
  }
  return backend_data->outputFormat_[i];
}

// Get the data from ith output.
mlperf_status_t mlperf_backend_get_output(mlperf_backend_ptr_t backend_ptr,
                                          uint32_t batchIndex,
                                          int32_t outputIndex, void **data) {
  QTIBackendHelper *backend_data = (QTIBackendHelper *)backend_ptr;
  if (backend_data->isTflite_) {
    return tflite_backend_get_output(backend_data->tfliteBackend_, batchIndex,
                                     outputIndex, data);
  }
  if (backend_data->snpeOutputLayers_ ==
      "Postprocessor/BatchMultiClassNonMaxSuppression") {
    // Reorder snpeOutputLayers_ for coco process_output
    const char *outputLayerName = backend_data->odLayerMap[outputIndex].c_str();
    *data = backend_data->bufs_[batchIndex].at(outputLayerName).data();
    return MLPERF_SUCCESS;
  } else if (backend_data->snpeOutputLayers_ == "transpose") {
    *data = backend_data->bufs_[int(batchIndex / backend_data->inputBatch_)]
                .at(Snpe_StringList_At(
                    backend_data->networkOutputTensorNamesHandle_, 0))
                .data() +
            (1 - outputIndex) * 384 * sizeof(float);
    return MLPERF_SUCCESS;
  }
  size_t size = sizeof(float);
  if (backend_data->outputBufferType_ ==
      QTIBackendHelper::QTIBufferType::UINT_8) {
    size = sizeof(uint8_t);
  }

  *data =
      backend_data->bufs_[int(batchIndex / backend_data->inputBatch_)]
          .at(Snpe_StringList_At(backend_data->networkOutputTensorNamesHandle_,
                                 outputIndex))
          .data() +
      (batchIndex % backend_data->inputBatch_) *
          int(backend_data->outputBatchBufsize_ / backend_data->inputBatch_) *
          size;
  return MLPERF_SUCCESS;
}

void *mlperf_backend_get_buffer(size_t n) {
  return backend_data_->getBuffer_(n, backend_data_->inputBatch_);
}

void mlperf_backend_release_buffer(void *p) {
  backend_data_->releaseBuffer_(p);
}

#ifdef __cplusplus
}
#endif  // __cplusplus
