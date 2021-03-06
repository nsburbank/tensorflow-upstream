#!/usr/bin/env bash
# Copyright 2017 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ==============================================================================

set -e
set -x

N_JOBS=$(grep -c ^processor /proc/cpuinfo)
N_GPUS=$(lspci|grep 'AMD/ATI'|wc -l)

echo ""
echo "Bazel will use ${N_JOBS} concurrent build job(s) and ${N_GPUS} concurrent test job(s)."
echo ""

# Run configure.
export PYTHON_BIN_PATH=`which python3`
export CC_OPT_FLAGS='-mavx'

export TF_NEED_ROCM=1
export TF_GPU_COUNT=${N_GPUS}

yes "" | $PYTHON_BIN_PATH configure.py

# Run bazel test command. Double test timeouts to avoid flakes.
bazel test --test_sharding_strategy=disabled --config=rocm --test_tag_filters=-no_oss,-oss_serial,-no_gpu,-benchmark-test -k \
    --test_lang_filters=py --jobs=${N_JOBS} --test_timeout 600,900,2400,7200 \
    --build_tests_only --test_output=errors --local_test_jobs=${TF_GPU_COUNT} --config=opt \
    --run_under=//tensorflow/tools/ci_build/gpu_build:parallel_gpu_execute -- \
    //tensorflow/... -//tensorflow/compiler/... -//tensorflow/contrib/... \
    -//tensorflow/python/distribute:distribute_coordinator_test \
    -//tensorflow/python/estimator:dnn_linear_combined_test \
    -//tensorflow/python/estimator:linear_test \
    -//tensorflow/python/feature_column:feature_column_v2_test \
    -//tensorflow/python/keras:cudnn_recurrent_test \
    -//tensorflow/python/kernel_tests:batch_matmul_op_test \
    -//tensorflow/python/kernel_tests:conv1d_test \
    -//tensorflow/python/kernel_tests:conv2d_backprop_filter_grad_test \
    -//tensorflow/python/kernel_tests:conv_ops_3d_test \
    -//tensorflow/python/kernel_tests:conv_ops_test \
    -//tensorflow/python/kernel_tests:dct_ops_test \
    -//tensorflow/python/kernel_tests:depthwise_conv_op_test \
    -//tensorflow/python/kernel_tests:fft_ops_test \
    -//tensorflow/python/kernel_tests:list_ops_test \
    -//tensorflow/python/kernel_tests:matmul_op_test \
    -//tensorflow/python/kernel_tests:pool_test \
    -//tensorflow/python/kernel_tests:pooling_ops_3d_test \
    -//tensorflow/python/kernel_tests:pooling_ops_test \
    -//tensorflow/python/kernel_tests:softplus_op_test \
    -//tensorflow/python/kernel_tests:softsign_op_test \
    -//tensorflow/python/ops/parallel_for:control_flow_ops_test \
    -//tensorflow/python/ops/parallel_for:gradients_test \
    -//tensorflow/python:layers_normalization_test \
    -//tensorflow/python:layout_optimizer_test \
    -//tensorflow/python:nn_fused_batchnorm_test

