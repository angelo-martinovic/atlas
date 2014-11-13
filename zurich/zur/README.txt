

  0. Dependencies:
    0.1 CUDA (drivers and CUDA toolkit 5.5)
      - run additionalFiles/cuda_5.5.22_linux_64.run -override compiler
      - remember the install path CUDAPATH
	  - make sure that the nVidia kernel module is at least 319.37

    0.1 opencv built with CUDA support

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
      3. compile the detector code

		3.1. if compilation fails due to incompatible protocol buffer files:
			- edit biclop/generate_protocol_buffer_files.sh and change the call of protoc to /scratch_net/biwisrv01_second/varcity/code/lib/protobuf-2.5.0/local/bin/protoc
			- follow the steps in the script
		    - change common_settings.cmake:
				  set(local_CUDA_LIB_DIR "/usr/lib/x86_64-linux-gnu")
  			          set(local_CUDA_LIB "/usr/lib/x86_64-linux-gnu/libcuda.so")

				include_directories(
					/scratch_net/biwisrv01_second/varcity/code/lib/protobuf-2.5.0/src
				  )

				  link_directories(
					/scratch_net/biwisrv01_second/varcity/code/lib/protobuf-2.5.0/local/lib
				  )
			
  2. run matlab, go to libsvm-3.14/matlab folder and run make
  3. run app.py
    Example:
    python app.py -o /scratch_net/biwisrv01_second/varcity/code/grammar/ATLAS/test1/ --datasetName haussmann --fold 1 --enableWindowDetector --windowDetectorName window-specific --enableDoorDetector --doorDetectorName door-specific
