/* Copyright 2020-2023 Samsung Electronics Co. LTD  All Rights Reserved.

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
#include "mbe_core.hpp"

#include <android/log.h>

#include <array>
#include <atomic>
#include <condition_variable>
#include <cstdio>
#include <iostream>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <string>
#include <thread>

#include "mbe_utils.hpp"

using namespace mbe;

static mbe_core_holder *mbe_core = nullptr;

bool mlperf_backend_matches_hardware(const char **not_allowed_message,
                                     const char **settings,
                                     const mlperf_device_info_t *device_info) {
  MLOGD("Check a support manufacturer: %s  model: %s",
        device_info->manufacturer, device_info->model);
  MLOGD("+ mlperf_backend_matches_hardware");

  *not_allowed_message = nullptr;

  int selected =
      core_ctrl::support_mbe(device_info->manufacturer, device_info->model);
  if (selected != CORE_INVALID) {
    MLOGV("backend core selected [%d]", selected);
    *settings = core_ctrl::get_benchmark_config(selected);
    return true;
  }

  MLOGE("Soc Not supported. Trying next backend");
  *not_allowed_message = "UnsupportedSoc";
  return false;
}

const char *mlperf_backend_vendor_name(mlperf_backend_ptr_t backend_ptr) {
  static const char name[] = "samsung";
  return name;
}

const char *mlperf_backend_accelerator_name(mlperf_backend_ptr_t backend_ptr) {
  return "samsung npu";
}

const char *mlperf_backend_name(mlperf_backend_ptr_t backend_ptr) {
  static const char name[] = "samsung";
  return name;
}

mlperf_status_t mlperf_backend_flush_queries(mlperf_backend_ptr_t backend_ptr) {
  return MLPERF_SUCCESS;
}

mlperf_backend_ptr_t mlperf_backend_create(
    const char *model_path, mlperf_backend_configuration_t *configs,
    const char *native_lib_path) {
  MLOGD("mlperf_backend_create");

  if (mbe_core) {
    MLOGD("mbe object exist.");
    mbe_core->unload_core_library();
  }

  MLOGD("ready to load mbe library");
  mbe_core = new mbe_core_holder();
  bool ret = mbe_core->load_core_library(native_lib_path);
  if (ret == false) return nullptr;
  mbe_core->create_fp(model_path, configs, native_lib_path);
  MLOGD("ptr of mbe_core[%p]", mbe_core);
  return (mlperf_backend_ptr_t)mbe_core;
}

int32_t mlperf_backend_get_input_count(mlperf_backend_ptr_t backend_ptr) {
  mbe_core_holder *ptr = (mbe_core_holder *)backend_ptr;
  MLOGD("+ mlperf_backend_get_input_count with ptr[%p]", ptr);
  return ptr->get_input_count_fp();
}

mlperf_data_t mlperf_backend_get_input_type(mlperf_backend_ptr_t backend_ptr,
                                            int32_t i) {
  mbe_core_holder *ptr = (mbe_core_holder *)backend_ptr;
  MLOGD("+ mlperf_backend_get_input_type with ptr[%p]", ptr);
  return ptr->get_input_type_fp(i);
}

mlperf_status_t mlperf_backend_set_input(mlperf_backend_ptr_t backend_ptr,
                                         int32_t batchIndex, int32_t i,
                                         void *data) {
  mbe_core_holder *ptr = (mbe_core_holder *)backend_ptr;
  MLOGD("+ mlperf_backend_set_input with mbe_core_holder[%p]", ptr);
  return ptr->set_input_fp(batchIndex, i, data);
}

int32_t mlperf_backend_get_output_count(mlperf_backend_ptr_t backend_ptr) {
  mbe_core_holder *ptr = (mbe_core_holder *)backend_ptr;
  MLOGD("+ mlperf_backend_get_output_count with ptr[%p]", ptr);
  return ptr->get_output_count_fp();
}

mlperf_data_t mlperf_backend_get_output_type(mlperf_backend_ptr_t backend_ptr,
                                             int32_t i) {
  mbe_core_holder *ptr = (mbe_core_holder *)backend_ptr;
  MLOGD("+ mlperf_backend_get_output_type with ptr[%p]", ptr);
  return ptr->get_output_type_fp(i);
}

mlperf_status_t mlperf_backend_issue_query(mlperf_backend_ptr_t backend_ptr) {
  mbe_core_holder *ptr = (mbe_core_holder *)backend_ptr;
  MLOGD("+ mlperf_backend_issue_query with ptr[%p]", ptr);
  return ptr->issue_query_fp();
}

mlperf_status_t mlperf_backend_get_output(mlperf_backend_ptr_t backend_ptr,
                                          uint32_t batchIndex, int32_t i,
                                          void **data) {
  mbe_core_holder *ptr = (mbe_core_holder *)backend_ptr;
  MLOGD("+ mlperf_backend_get_output with ptr[%p]", ptr);
  return ptr->get_output_fp(batchIndex, i, data);
}

void mlperf_backend_convert_inputs(void *backend_ptr, int bytes, int width,
                                   int height, uint8_t *data) {
  mbe_core_holder *ptr = (mbe_core_holder *)backend_ptr;
  MLOGD("+ mlperf_backend_convert_inputs with ptr[%p]", ptr);
  ptr->convert_inputs_fp(bytes, width, height, data);
}

void mlperf_backend_delete(mlperf_backend_ptr_t backend_ptr) {
  mbe_core_holder *ptr = (mbe_core_holder *)backend_ptr;
  MLOGD("+ mlperf_backend_delete with ptr[%p]", ptr);
  ptr->delete_fp();

  delete (ptr);
  ptr = nullptr;
}

void *mlperf_backend_get_buffer(size_t size) {
  MLOGD("+ mlperf_backend_get_buffer with size[%zu]", size);
  return mbe_core->get_buffer_fp(size);
}

void mlperf_backend_release_buffer(void *p) {
  MLOGD("+ mlperf_backend_release_buffer with ptr[%p]", p);
  mbe_core->release_buffer_fp(p);
}
