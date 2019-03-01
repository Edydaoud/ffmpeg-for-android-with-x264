#!/bin/bash

#NDK_ROOT="${1:-${NDK_ROOT}}"
NDK_ROOT=/home/cmm/Desktop/android-ndk-r16b

export ANDROID_NDK=$NDK_ROOT

#ffmpeg
export LD_LIBRARY_PATH=/usr/local/ffmpeg/lib
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/ffmpeg/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PKG_CONFIG_LIBDIR:/usr/local/ffmpeg/lib
#export FFMPEG_INCLUDE_DIRS=$FFMPEG_INCLUDE_DIRS:/usr/local/ffmpeg/include

#cuda
#CUDA_ROOT=/usr/local/cuda-8.0
#export CUDA_PATH=$CUDA_PATH:$CUDA_ROOT
#export CUDA_SDK_ROOT_DIR=$CUDA_SDK_ROOT_DIR:$CUDA_ROOT/lib
#export CUDA_INCLUDE_DIRS=$CUDA_ROOT/include
#export CUDA_LIBRARIES=$CUDA_ROOT/lib


### ABIs setup
#declare -a ANDROID_ABI_LIST=("x86" "x86_64" "armeabi-v7a with NEON" "arm64-v8a")
#declare -a ANDROID_ABI_LIST=("x86" "x86_64" "armeabi" "arm64-v8a" "armeabi-v7a" "mips" "mips64")
#declare -a ANDROID_ABI_LIST=("x86" "x86_64" "armeabi" "arm64-v8a" "armeabi-v7a")
declare -a ANDROID_ABI_LIST=("armeabi-v7a")


### path setup
#SCRIPT=$(readlink -f $0)
SCRIPT=$(stat -f $0)
#WD=`dirname $SCRIPT`
WD=$(pwd 'dirname $SCRIPT')
OPENCV_ROOT="${WD}/opencv"
N_JOBS=${N_JOBS:-8}

### Download android-cmake
if [ ! -d "${WD}/android-cmake" ]; then
    echo 'Cloning android-cmake'
    git clone https://github.com/taka-no-me/android-cmake.git
fi

INSTALL_ROOT="${WD}/android_opencv_sample"
#rm -rf "${INSTALL_DIR}/opencv"

### Make each ABI target iteratly and sequentially
for i in "${ANDROID_ABI_LIST[@]}"
do
    ANDROID_ABI="${i}"
    echo "Start building ${ANDROID_ABI} version"

    if [ "${ANDROID_ABI}" = "armeabi" ]; then
        API_LEVEL=19
    else
        API_LEVEL=21
    fi

    INSTALL_DIR="${INSTALL_ROOT}/opencv-${ANDROID_ABI}"
    
    #remove install dir folder
    rm -rf "${INSTALL_DIR}"

    temp_build_dir="${OPENCV_ROOT}/platforms/build_android__sample_${ANDROID_ABI}"
    ### Remove the build folder first, and create it
    rm -rf "${temp_build_dir}"
    mkdir -p "${temp_build_dir}"
    cd "${temp_build_dir}"

    cmake -D CMAKE_BUILD_WITH_INSTALL_RPATH=ON \
          -D CMAKE_TOOLCHAIN_FILE=${WD}/opencv/platforms/android/android.toolchain.cmake \
          -D ANDROID_NDK="${NDK_ROOT}" \
          -D ANDROID_NATIVE_API_LEVEL=${API_LEVEL} \
          -D ANDROID_ABI="${ANDROID_ABI}" \
    	  -D BUILD_EXAMPLES=OFF \
          -D BUILD_ANDROID_EXAMPLES=OFF \
          -D BUILD_DOCS=OFF \
          -D BUILD_PERF_TESTS=OFF \
          -D BUILD_TESTS=OFF \
          -D WITH_FFMPEG=ON \
          -D WITH_OPENCL=ON \
          -D BUILD_SHARED_LIBS=ON \
          -D OPENCV_ENABLE_NONFREE=ON \
          -D OPENCV_EXTRA_MODULES_PATH="${WD}/opencv_contrib/modules/"  \
          -D CMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
          -D BUILD_ANDROID_PROJECTS=OFF \
	  -D CMAKE_BUILD_TYPE=Release \
	  -D PKG_CONFIG_EXECUTABLE=/usr/bin/pkg-config \
	  -D OPENCV_FFMPEG_SKIP_DOWNLOAD=TRUE \
          ../..

    # Build it
    make -j${N_JOBS}
    # Install it
    make install/strip
    ### Remove temp build folder
    cd "${WD}"
    rm -rf "${temp_build_dir}"
    echo "end building ${ANDROID_ABI} version"
done
