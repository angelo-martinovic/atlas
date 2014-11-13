#!/bin/bash

#PATH_TO_WX="/scratch_net/biwisrv01_second/varcity/code/lib/wxGTK-2.8.11/"

HOSTNAME=`hostname`
CODEBASE=`pwd`
LAB="biwi"

# 1. Download and configure STAIR Vision Library. 
if [ -d $CODEBASE/lasik-2.4 ]; then
  echo "SVL already installed. Skipping..."
else
  wget -c http://sourceforge.net/projects/stairvision/files/stairvision/2.4/stairvision-src-2.4.tar.gz || exit 1
  tar xzvf stairvision-src-2.4.tar.gz
  rm stairvision-src-2.4.tar.gz
  
  
  cd lasik-2.4/external
  

  # Change VERSION of Eigen to 2.0.16
  sed -i 's/2.0.12/2.0.16/g' install.sh
  sed -i 's/mv eigen/mv eigen-eigen-9ca09dbd70ce/g' install.sh

  # Change VERSION of wxWidgets to 2.8.12
  sed -i 's/2.8.11/2.8.12/g' install.sh

  if [ $LAB = "visics" ]; then
    # Increase the compilation speed
    sed -i 's/make/make -j8/g' install.sh
     # wxWidgets need to explicitly link to x11
    sed -i "34i    export LDFLAGS='-L/lib64 -lX11'" install.sh
    sed -i "37i    unset LDFLAGS" install.sh
    
    PATH_TO_OPENCV="/users/visics/amartino/no_backup/opencv2.4_CUDA/"
    PATH_TO_CUDA="\/users\/visics\/amartino\/no_backup\/cuda-5.5\/"
    PATH_TO_SDL="\/users\/visics\/amartino\/no_backup\/sdl\/"

  elif [ $LAB = "biwi" ]; then
    # Increase the compilation speed
    sed -i 's/make/make -j2/g' install.sh
    
    sed -i "32i    echo 'Running Debian-specific adjustments!'" install.sh
    sed -i "33i    sed -i 's/0.2.8/0.2.9/g' build/aclocal/bakefile.m4" install.sh
    sed -i "34i    sed -i 's/\\\/usr\\\/\\\$wx_cv_std_libpath/\\\/usr\\\/\\\$wx_cv_std_libpath \\\/usr\\\/lib\\\/x86_64-linux-gnu/g' configure.in" install.sh
    sed -i "35i    autoconf -o configure configure.in" install.sh

    PATH_TO_OPENCV="/scratch_net/biwisrv01_second/varcity/code/lib/opencv-2.4.9/localCUDA/"
    PATH_TO_SDL="/scratch_net/biwisrv01_second/varcity/code/lib/SDL-1.2.15/local/"

    # needs to be escaped
    PATH_TO_CUDA="\/scratch_net\/biwisrv01_second\/varcity\/code\/lib\/cuda-5.5\/"

  else
    echo 'unknown lab!'
    exit
  fi
  
  # Link opencv
  ln -s $PATH_TO_OPENCV opencv

  # Install 
  ./install.sh || exit 1

  # Fix the unistd.h include problems
  cd ..
  sed -i "45i#include <unistd.h>" svl/lib/base/svlFileUtils.cpp
  sed -i "40i#include <unistd.h>" svl/apps/vision/buildPatchResponseCache.cpp

  # Copy the make.local file to build only the vision apps
  cp ../additionalFiles/make.local .

  sed -i "143iCFLAGS += -fpermissive" make.mk
  sed -i "144iLFLAGS += -fpermissive -lX11" make.mk
  
  
  make -j8 external
  make -j8 svllibs
  make -j8 svlprojs
fi

# 2. Compile EDISON 
#cd edison
#make

# 3. Create a working directory
#mkdir work

# UNFORTUNATELY, WE CANNOT SHARE biclop.zip 
# DUE TO LICENSING ISSUES.
# A COMPILED VERSION OF objects_detection CAN
# BE FOUND IN THE detectors/ FOLDER.

# IF YOU WANT TO USE THE DETECTORS, PLEASE
# ASK THE ORIGINAL AUTHORS OF THE DETECTOR: 
# https://bitbucket.org/rodrigob/doppia/
# TO PROVIDE THEIR CODE

# 1. Set up the detectors
#if [ -d $CODEBASE/biclop ]; then
#  echo "Detectors already installed. Skipping..."
#else
#  unzip additionalFiles/biclop.zip
#  cd biclop

#  echo 'Generating protocol buffer files...'
#  ./generate_protocol_buffer_files.sh

#  echo 'Modifying the cmake files...'
#  # Add the current host to the list of machines
#  sed -i '/set(VISICS_MACHINES/a  "'$HOSTNAME'"' common_settings.cmake

#  # Comment out the unnecessary lines
#  sed -i '/set(CUDA_SDK_ROOT_DIR/s/^/#/' common_settings.cmake
#  sed -i '/set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS} --compiler-options/s/^/#/' common_settings.cmake

  # Set the cuda dirs
#  sed -i 's/set(local_CUDA_CUT_INCLUDE_DIRS.*/set(local_CUDA_CUT_INCLUDE_DIRS "'$PATH_TO_CUDA'include")/g' common_settings.cmake
#  sed -i 's/set(local_CUDA_CUT_LIBRARY_DIRS.*/set(local_CUDA_CUT_LIBRARY_DIRS "'$PATH_TO_CUDA'lib")/g' common_settings.cmake

#  sed -i 's/set(CUDA_NVCC_EXECUTABLE  \/bin\/nvcc )/set(CUDA_NVCC_EXECUTABLE  '$PATH_TO_CUDA'bin\/nvcc )/g' common_settings.cmake

#  cd src/applications/objects_detection
#  sed -i '20 s/^/#/' CMakeLists.txt

  # Add opencv and sdl, lib and include folder
#  sed -i '/set(local_LIBRARY_DIRS/a\  "'$PATH_TO_OPENCV'lib"' CMakeLists.txt
#  sed -i '/set(local_INCLUDE_DIRS/a\  "'$PATH_TO_OPENCV'include"' CMakeLists.txt

#  sed -i '/set(local_LIBRARY_DIRS/a\  "'$PATH_TO_SDL'"' CMakeLists.txt
#  sed -i '/set(local_INCLUDE_DIRS/a\  "'$PATH_TO_SDL'"' CMakeLists.txt

  # Make the CUDA toolkit and SDK dirs available
#  sed -i '/find_package(CUDA 4.0 REQUIRED)/i\set(CUDA_TOOLKIT_ROOT_DIR "'$PATH_TO_CUDA'")\nset(CUDA_SDK_ROOT_DIR "'$PATH_TO_CUDA'")\nset(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "default to relwithdebinfo" FORCE)' CMakeLists.txt

#  cmake .
#  make -j8

#  if [ $? -ne 0 ]; then
#    make
#  fi

#  cd ../../../../
#  cp additionalFiles/detections_to_wnd_eval_normalized.py biclop/tools/objects_detection
   
#fi