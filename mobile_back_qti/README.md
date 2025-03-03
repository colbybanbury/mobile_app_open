# MLPerf app for Android and Windows on Arm with SNPE Backend

This subdirectory contains the QTI backend for the MLPerf app, an app-based
implementation of [MLPerf Inference](https://github.com/mlperf/inference) tasks.

## MLPerf Flutter app for mobile

Following instructions build the libqtibackend.so backend and prepares the libraries and
SNPE DLC files for integration with the MLPerf flutter app. These DLC files have been
uploaded with the other submission files to here: `<path where needs to be uploaded>`

## Requirements for LA

<!-- markdown-link-check-disable-next-line -->
* [SNPE SDK](https://developer.qualcomm.com/software/qualcomm-neural-processing-sdk/tools)
  * Version 2.7.0
* Linux machine capable of running Ubuntu 18.04 docker images

### Optional

If you wish to rebuild the DLC files yourself, you will have these additional requirements:

* Imagenet dataset (LSVRC2012_img_val.tar) put in the build/imagenet/downloads directory
* Linux machine also capable of running Tensorflow debian based docker images

Use your browser to download the SNPE SDK using the links above.

Create your Github personal access token.

```shell
export GITHUB_TOKEN=<your-personal-access-token>
cd DLC/ && make
```

It will take 2 hours on an 8-core Xeon workstation to generate the DLC files.

## Building the MLPerf app with the QTI backend

Clone mlperf_app_open

```shell
git clone https://github.com/mlcommons/mobile_app_open
cd mobile_app_open
```

* Download and extract the SNPE SDK (from Requirements above) to mobile_app_open/mobile_back_qti

* If you have an HTTP proxy, you may need the following

```shell
sudo apt install ca-certificates-java
export USE_PROXY_WORKAROUND=1
```

Build with the following build command.

```shell
make OFFICIAL_BUILD=true FLUTTER_BUILD_NUMBER=1  WITH_QTI=1 docker/flutter/android/release
```

This will generate the MLPerf flutter app with QTI backend in ```mobile_app_open/output/android-apks/release.apk```

## Building the QTI backend lib

To build only the QTI backend:

```shell
git clone https://github.com/mlcommons/mobile_app_open
make WITH_QTI=1 libqtibackend
```

## Backend Specific Task Config file

The task config settings are embedded in libqtibackend.so. These settings contain the
backend specific data for each task to be run. This backend assumes a few things about
the settings:

1. All the models use "SNPE" for the configuration name and use "snpe_dsp" or "psnpe_dsp" for the accelerator value when using SNPE / PSNPE.

## MLPerf Commandline app for Windows on Arm

Following instructions build the libqtibackend backend and prepares the binaries for running the MLPerf commandline app on Windows. The DLC files have been
uploaded with the other submission files to here: `<path where needs to be uploaded>`

## Requirements for WoS

<!-- markdown-link-check-disable-next-line -->
* [SNPE windows SDK] (<https://developer.qualcomm.com/software/qualcomm-neural-processing-sdk/tools>)
  * Version 2.7.0
* Windows x86 machine

## Setting up the environment

* Install Visual Studio (atleast 2019): <https://visualstudio.microsoft.com/vs/> with ARM compilers.
* Visual Studio Community: <https://learn.microsoft.com/en-us/visualstudio/releases/2019/release-notes> is also supported.
* Add 2019 in the name of the BAZEL_VC path
* Follow the windows setup intructions from [here](https://github.com/mlcommons/mobile_app_open/blob/master/docs/environment-setup/env-setup-windows.md)
  * Flutter and protoc installation is not required
  * Make sure to install the tested environment library versions `Use --version during choco install`

## Building the MLPerf commandline app for Windows on Arm

Clone mlperf_app_open

```shell
git clone https://github.com/mlcommons/mobile_app_open
cd mobile_app_open
git checkout <Qualcomm's branch>
```

Download and extract the SNPE SDK (from Requirements above) to mobile_app_open/mobile_back_qti

Build with the following build command.

```shell
make WITH_QTI=1 WITH_TFLITE=0 MSVC_ARM_DLLS=<path to arm64 RT files> cmdline/windows/release
```

```shell
Sample path to arm64RT files: "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Redist\MSVC\14.29.30133\arm64\Microsoft.VC142.CRT"
```

This will generate binary files in output\flutter\cmdline

## Running the commandline app on Windows on Arm

* push all the command line files in to the Windows device.
* push all the datasets to the device to C:\Dropbox\lite_datasets and complete datasets to C:\Dropbox\mlperf_datasets
* push all the models to the device to C:\Dropbox\mlperf_models
* open powershell on the device. CD to the cmdline folder on the device.

Run performance mode with following command

```shell
.\run_performance_tests.bat --models <path to mlperf_models> --dataset <path to mlperf_lite_datasets>
```

Run accuracy mode with following command

```shell
.\run_accuracy_test.bat --models <path to mlperf_models> --dataset <path to mlperf_datasets>
```

* see the results in accuracy_results.txt and performance_results.txt

## FAQ

### What devices does this backend support?

This backend only supports SDM888/SDM888 Pro, SDM778G, SD7G1, SD8G1, SD8Pro G1, SD8G2 devices.
Other Snapdragon based devices will not run the MLPerf app. Future updates of the app will provide
additional device support.

### Is SNPE used to run all the models?

Yes. All the models use SNPE for execution for current version.
