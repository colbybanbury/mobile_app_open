set /A cooldown_period=5
set /A min_query=1000
set /A min_duration=60000
set results_prefix=accuracy_results_
set results_suffix=.txt
set test_case_suffix=_accuracy_logs
set results_file=accuracy_results.txt
del %results_file%
set dataset_path=""
set models_path=""

:loop
IF NOT "%1"=="" (
    IF "%1"=="--dataset" (
        SET dataset_path=%2
        SHIFT
    )
    IF "%1"=="--models" (
        SET models_path=%2
        SHIFT
    )
    SHIFT
    GOTO :loop
)

if %dataset_path%=="" (
    GOTO :dataset_end
)

if %models_path%=="" (
    GOTO :models_end
)

set test_case=image_classification
mkdir %test_case%%test_case_suffix%
.\main.exe EXTERNAL imagenet --mode=AccuracyOnly --images_directory=%dataset_path%\imagenet\img --offset=1 --output_dir=%test_case%%test_case_suffix% --min_query_count=%min_query% --min_duration=%min_duration% --single_stream_expected_latency_ns=1000000 --groundtruth_file=%dataset_path%\imagenet\imagenet_val_full.txt --model_file=%models_path%\mobilenet_edgetpu_224_1.0_htp.dlc --lib_path=libqtibackend.dll --native_lib_path=. --results_file=%results_prefix%%test_case%%results_suffix%
timeout /t %cooldown_period% /nobreak
type %results_prefix%%test_case%%results_suffix% >> %results_file%

set test_case=object_detection
mkdir %test_case%%test_case_suffix%
.\main.exe EXTERNAL coco --mode=AccuracyOnly --images_directory=%dataset_path%\coco\img --offset=1   --output_dir=%test_case%%test_case_suffix% --min_query_count=%min_query% --min_duration=%min_duration% --single_stream_expected_latency_ns=1000000 --groundtruth_file=%dataset_path%\coco\coco_val_full.pbtxt --model_file=%models_path%\ssd_mobiledet_qat_htp.dlc --lib_path=libqtibackend.dll --native_lib_path=. --num_classes=91  --results_file=%results_prefix%%test_case%%results_suffix%
timeout /t %cooldown_period% /nobreak
type %results_prefix%%test_case%%results_suffix% >> %results_file%

set test_case=image_segmentation
mkdir %test_case%%test_case_suffix%
.\main.exe EXTERNAL ade20k --mode=AccuracyOnly --images_directory=%dataset_path%\ade20k\images --num_class=31 --output_dir=%test_case%%test_case_suffix% --min_query_count=%min_query% --min_duration=%min_duration% --single_stream_expected_latency_ns=1000000 --ground_truth_directory=%dataset_path%\ade20k\annotations --model_file=%models_path%\mobile_mosaic_htp.dlc --lib_path=libqtibackend.dll --native_lib_path=. --results_file=%results_prefix%%test_case%%results_suffix%
timeout /t %cooldown_period% /nobreak
type %results_prefix%%test_case%%results_suffix% >> %results_file%

set test_case=language_understanding
mkdir %test_case%%test_case_suffix%
.\main.exe EXTERNAL squad --mode=AccuracyOnly --input_file=%dataset_path%\squad\squad_eval.tfrecord --output_dir=%test_case%%test_case_suffix% --min_query_count=%min_query% --min_duration=%min_duration% --single_stream_expected_latency_ns=1000000 --groundtruth_file=%dataset_path%\squad\squad_groundtruth.tfrecord --model_file=%models_path%\mobilebert_quantized_htp.dlc --lib_path=libqtibackend.dll --native_lib_path=. --results_file=%results_prefix%%test_case%%results_suffix%
timeout /t %cooldown_period% /nobreak
type %results_prefix%%test_case%%results_suffix% >> %results_file%

set test_case=super_resolution
mkdir %test_case%%test_case_suffix%
.\main.exe EXTERNAL SNUSR --mode=AccuracyOnly --images_directory=%dataset_path%\super_resolution\lr --output_dir=%test_case%%test_case_suffix% --min_query_count=%min_query% --min_duration=%min_duration% --single_stream_expected_latency_ns=1000000 --ground_truth_directory=%dataset_path%\super_resolution\hr --model_file=%models_path%\snusr_htp.dlc --lib_path=libqtibackend.dll --native_lib_path=. --results_file=%results_prefix%%test_case%%results_suffix%
timeout /t %cooldown_period% /nobreak
type %results_prefix%%test_case%%results_suffix% >> %results_file%

set test_case=image_classification_offline
mkdir %test_case%%test_case_suffix%
.\main.exe EXTERNAL imagenet --mode=AccuracyOnly --scenario=Offline --batch_size=12288 --images_directory=%dataset_path%\imagenet\img --offset=1 --output_dir=%test_case%%test_case_suffix% --min_query_count=24576 --min_duration=0 --single_stream_expected_latency_ns=1000000 --groundtruth_file=%dataset_path%\imagenet\imagenet_val_full.txt --model_file=%models_path%\mobilenet_edgetpu_224_1.0_htp_batched_sd8pg1.dlc --lib_path=libqtibackend.dll --native_lib_path=. --results_file=%results_prefix%%test_case%%results_suffix%
type %results_prefix%%test_case%%results_suffix% >> %results_file%

:dataset_end
echo "set dataset path using --dataset"

:models_end
echo "set models path using --models"
