#!/usr/bin/env bash

# Install SageAttention2.2

pip install sageattention==2.2.0 --no-build-isolation


#export EXT_PARALLEL=4 NVCC_APPEND_FLAGS="--threads 8" MAX_JOBS=32

#echo "Starting SageAttention build..."

#cd /tmp
#git clone https://github.com/thu-ml/SageAttention.git
#cd SageAttention
#git reset --hard 68de379
#pip install -e .

#echo "SageAttention build completed" > /tmp/sage_build_done

