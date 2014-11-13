

  0. Dependencies:
    0.1 CUDA (drivers and CUDA toolkit 5.5) - works with CUDA 4.2 as well (BIWI)
        For CUDA 5.5:
              - run additionalFiles/cuda_5.5.22_linux_64.run -override compiler
              - remember the install path CUDAPATH
                  - make sure that the nVidia kernel module is at least 319.37

    0.1 opencv built with CUDA support (4.2 at BIWI, 5.5 VISICS)

    0.2 libSDL 1.2
      If you want to install it to a local folder SDLPATH
      Download from http://www.libsdl.org/release/SDL-1.2.15.tar.gz
      Untar, enter folder
        mkdir release
        cd release
        configure --prefix=SDLPATH 
        make
        make install
      If the compilation fails, replace the SDL-1.2.15/src/video/x11/SDL_x11sym.h with 
      the version from additionalFiles/

    0.3 protobuf-devel

    0.4 libpng

 On debian: 
        0.1 create a symbolic link to lasik-2.4

  1. run installAll.sh
    This script will : 

      1. install the SVL library with the necessary dependencies
      2. compile the EDISON segmentation tool
      3. --compile the detector code--
	  # UNFORTUNATELY, WE CANNOT SHARE THE SOURCE CODE OF THE DETECTORS
	  # DUE TO LICENSING ISSUES.
	  # A COMPILED VERSION OF objects_detection CAN
	  # BE FOUND IN THE detectors/ FOLDER.

	  # IF YOU WANT TO COMPILE THE DETECTORS YOURSELF, PLEASE
	  # ASK THE ORIGINAL AUTHORS OF THE DETECTOR FOR THEIR CODE: 
	  # https://bitbucket.org/rodrigob/doppia/

                3.1. if compilation fails due to incompatible protocol buffer files (BIWI):
                        - edit biclop/generate_protocol_buffer_files.sh and change the call of protoc to /scratch_net/biwisrv01_second/varcity/code/lib/protobuf-2.5.0/local/bin/protoc
                        - follow the remaining steps in installAll.sh (run the provided sed commands, or change files manually)

      4. (BIWI) Make sure the following is written in biclop/common_settings.cmake, under if(HOSTED_AT_VISICS GREATER -1):
        set(local_CUDA_LIB_DIR "/usr/lib/x86_64-linux-gnu")
        set(local_CUDA_LIB "/usr/lib/x86_64-linux-gnu/libcuda.so")
        set(local_CUDA_CUT_INCLUDE_DIRS "/usr/pack/cuda-4.2-bs/amd64-debian-linux6.0/cuda/include")
        set(local_CUDA_CUT_LIBRARY_DIRS "/usr/pack/cuda-4.2-bs/amd64-debian-linux6.0/cuda/lib")
        set(CUDA_NVCC_EXECUTABLE  /usr/pack/cuda-4.2-bs/amd64-debian-linux6.0/cuda/bin/nvcc   )
        set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS} -arch=sm_20 --compiler-bindir=/scratch_net/biwisrv01_second/varcity/code/grammar/ATLAS/tmp)
        (If the compiler-bindir flag breaks the compilation, remove it. The tmp folder contains symlinks to gcc-4.6 and g++-4.6 which were needed to compile old CUDA stuff)

        include_directories(
                /scratch_net/biwisrv01_second/varcity/code/lib/protobuf-2.5.0/src
          )

        link_directories(
                /scratch_net/biwisrv01_second/varcity/code/lib/protobuf-2.5.0/local/lib
        )

        5. (BIWI) Make sure the following is written in biclop/src/applications/objects_detection/CMakeLists.txt:
        if(USE_GPU)
                set(CUDA_TOOLKIT_ROOT_DIR "/usr/pack/cuda-4.2-bs/amd64-debian-linux6.0/cuda/")
                set(CUDA_SDK_ROOT_DIR "/usr/pack/cuda-4.2-bs/amd64-debian-linux6.0/cuda")
        ...

        set(local_LIBRARY_DIRS
                "/scratch_net/biwisrv01_second/varcity/code/lib/SDL-1.2.15/local/"
                "/scratch_net/biwisrv01_second/varcity/code/lib/opencv-2.4.9/localCUDA/lib"
        ...

        set(local_INCLUDE_DIRS
                "/scratch_net/biwisrv01_second/varcity/code/lib/SDL-1.2.15/local/"
                "/scratch_net/biwisrv01_second/varcity/code/lib/opencv-2.4.9/localCUDA/include"

  2. Create mex files for libsvm-3.14: matlab, go to libsvm-3.14/matlab folder and run make
  3. run app.py
    Example:

    python app.py -o /scratch_net/biwisrv01_second/varcity/code/grammar/ATLAS/test1/ --datasetName haussmann --fold 1 --enableWindowDetector --windowDetectorName window-specific --enableDoorDetector --doorDetectorName door-specific

        (delete the test1 folder if it already exists)
