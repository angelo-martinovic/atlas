import sys,os,subprocess,re
from time import time,sleep
#from adjacency import createAdjacency
#import Image
from datetime import datetime
from glob import glob
import argparse

if __name__=="__main__":
    print >>sys.stderr, "Processing starts."
    
    parser = argparse.ArgumentParser(description='ATLAS: A Three Layered Approach to Facade Parsing')

    parser.add_argument('-o', action="store", dest="directoryName",default="")
    
    parser.add_argument('--datasetName', action="store", dest="datasetName", default="haussmann")
    parser.add_argument('--fold', action="store", dest="fold", type=int, default=1)
    
    parser.add_argument('--minRegionArea', action="store", dest="minRegionArea", type=int, default=45)
    parser.add_argument('--enableWindowDetector', action="store_true", default=False)
    parser.add_argument('--enableDoorDetector', action="store_true", default=False)
    parser.add_argument('--windowDetectorName', action="store", dest="windowDetectorName", default="window-generic")
    parser.add_argument('--doorDetectorName', action="store", dest="doorDetectorName", default="door-generic")
   
    #parser.add_argument('--RNNConfigFile', action="store", dest="RNNConfigFile", default="haussmannFold1.mat")
    #parser.add_argument('--mrfWindowAlpha', action="store", dest="mrfWindowAlpha", type=float, default=0.75)
    #parser.add_argument('--mrfDoorAlpha', action="store", dest="mrfDoorAlpha", type=float, default=7)
    #parser.add_argument('--mrfLambda', action="store", dest="mrfLambda", type=float, default=6.5)
    
    
    params = parser.parse_args()
    if not params.datasetName:
      print "No dataset specified!"
      sys.exit()
    
    
    if params.windowDetectorName.endswith("specific"):
      windowDetectorName = params.datasetName + "_" + params.windowDetectorName + "_fold_" + str(params.fold)
      windowDetectorConfigFile = "detector/configs/" + params.datasetName + "_" + params.windowDetectorName + ".ini"
    else:
      windowDetectorName = params.windowDetectorName
      windowDetectorConfigFile = "detector/configs/" + params.windowDetectorName + ".ini"
      
    if params.doorDetectorName.endswith("specific"):
      doorDetectorName = params.datasetName + "_" + params.doorDetectorName + "_fold_" + str(params.fold)
      doorDetectorConfigFile = "detector/configs/" + params.datasetName + "_" +params.doorDetectorName + ".ini"
    else:
      doorDetectorName = params.doorDetectorName
      doorDetectorConfigFile = "detector/configs/" + params.doorDetectorName + ".ini"
      
      
    windowDetectorModelFile = "detector/models/" + windowDetectorName  + ".bin"
    doorDetectorModelFile = "detector/models/" + doorDetectorName + ".bin"
      
    
    #Runs all scripts for image processing
    dirName = params.directoryName
    if not dirName:
      print "No output directory specified!"
      sys.exit()
      

      
    dirName = os.path.realpath(dirName)

    if not dirName.endswith("/"):
      dirName = dirName+"/"
  
    logfile = open('log.txt','a')
    currTime = datetime.now()
    ct = currTime.timetuple()
    print >>logfile, '[%04d/%02d/%02d %02d:%02d:%02d] Received "%s"' % (ct.tm_year,ct.tm_mon,ct.tm_mday,ct.tm_hour,ct.tm_min,ct.tm_sec, dirName )
    print '[%04d/%02d/%02d %02d:%02d:%02d] Received "%s"' % (ct.tm_year,ct.tm_mon,ct.tm_mday,ct.tm_hour,ct.tm_min,ct.tm_sec, dirName)
    logfile.close()
    
    try:
	devnull = open('/dev/null', 'w')
        currTime = time()
        
	print "0. Creating the work folder: " + dirName
        
        command = "mkdir "+dirName
       
        retcode = subprocess.call(command,shell=True)
	if retcode <> 0:
            print >>sys.stderr, "mkdir terminated with code", retcode, "...\nTerminated."
            sys.exit()
        else:
            print "0. Success." ,time()  - currTime, "seconds elapsed."
            
        filelist = "datasets/"+params.datasetName+"/folds/evalList"+str(params.fold)+".txt"    
        print "0. Copying files given in: " + filelist
        with open(filelist) as f:
	  lines=f.read().splitlines()
        
        
        
        imagesJPG =      ["datasets/"+params.datasetName+"/" + s + ".jpg" for s in lines]
        imagesPNG =      ["datasets/"+params.datasetName+"/" + s + ".png" for s in lines]
        images = imagesJPG + imagesPNG
        groundtruth = ["datasets/"+params.datasetName+"/" + s + ".txt" for s in lines]
        rect = ["datasets/"+params.datasetName+"/" + s + "rect.dat" for s in lines]
        
        command = ["cp"]+images+[dirName]
        retcode = subprocess.call(command)
            
	command = ["cp"]+groundtruth+[dirName]
	retcode = subprocess.call(command)
	
	command = ["cp"]+rect+[dirName]
	retcode = subprocess.call(command)

        
        print "0. Copied "+str(len(lines))+" images."

        #-------------------------------------------------------------------------------------------#
        #-------------------------------------------------------------------------------------------#
        #-------------------------------------------------------------------------------------------#
        currTime = time()
        print "1. Running the mean shift segmentation."
        
        command = "edison/segmentImages.sh "+dirName+" " + str(params.minRegionArea)
        retcode = subprocess.call(command.split())
        
        if retcode <> 0:
            print >>sys.stderr, "edison terminated with code", retcode, "...\nTerminated."
            sys.exit()
        else:
            print "1. Success." ,time()  - currTime, "seconds elapsed."
        
        
        #-------------------------------------------------------------------------------------------#
        #-------------------------------------------------------------------------------------------#
        #-------------------------------------------------------------------------------------------#
        currTime = time()
        print "2. Running the Gould feature extraction."
        my_env = os.environ
        my_env["LD_LIBRARY_PATH"] = "lasik-2.4/external/opencv/lib"
        command = "lasik-2.4/bin/segImageExtractFeatures -o "+dirName+" "+dirName
        
        retcode = subprocess.call(command.split(), stdout=devnull, env=my_env)
        if retcode <> 0:
            print >>sys.stderr, "gould terminated with code", retcode, "...\nTerminated."
            sys.exit()
        else:
            print "2. Success." ,time()  - currTime, "seconds elapsed."
        
      
        #-------------------------------------------------------------------------------------------#
        #-------------------------------------------------------------------------------------------#
        #-------------------------------------------------------------------------------------------#
        currTime = time()
        
	print "3. Running the detectors."
        
        # Create a folder with images only, to run the detector
        command = "mkdir "+dirName+"imgs"
        retcode = subprocess.call(command.split())
	if retcode <> 0:
            print >>sys.stderr, "dir creation terminated with code", retcode, "...\nTerminated."
            sys.exit()
            
	command = " ".join(["cp"]+glob(dirName+"*.jpg")+[dirName+"imgs/"])
        retcode = subprocess.call(command,shell=True)
	if retcode <> 0:
            print >>sys.stderr, "image copy terminated with code", retcode, "...\nTerminated."
            sys.exit()
            
        currTime = time() 
        if (params.enableWindowDetector):
	    print "3.1. Running the window detector."
	    # Run the detector
            command = "detector/objects_detection -c " +\
            windowDetectorConfigFile+" --objects_detector.model "+windowDetectorModelFile +\
            " --recording_path " + dirName + " --process_folder " + dirName +"imgs"

            print command
            retcode = subprocess.call(command.split())
            if retcode <> 0:
                print >>sys.stderr, "detector terminated with code", retcode, "...\nTerminated."
                sys.exit()
            else:
                print "3.1. Window detector: success." ,time()  - currTime, "seconds elapsed."
             
            # Create output files
            os.chdir("detector/tools/objects_detection")
            command = "python detections_to_wnd_eval_normalized.py  -d ../../../"+dirName+"detections.data_sequence -o ../../../"+dirName+"detections_"+params.windowDetectorName+" -m ../../../"+windowDetectorModelFile
            retcode = subprocess.call(command.split(), stdout=devnull)
            if retcode <> 0:
                print >>sys.stderr, "output file creation terminated with code", retcode, "...\nTerminated."
                sys.exit()
                
            os.chdir("../../../")
	    command = "rm "+dirName+"detections.data_sequence"
            retcode = subprocess.call(command.split())
            
        currTime = time()        
        if (params.enableDoorDetector):
	    print "3.2. Running the door detector."
	    # Run the detector
            command = "detector/objects_detection -c "+\
            doorDetectorConfigFile+" --objects_detector.model "+doorDetectorModelFile  +\
            " --recording_path " + dirName + " --process_folder " + dirName +"imgs"
            retcode = subprocess.call(command.split())
            if retcode <> 0:
                print >>sys.stderr, "detector terminated with code", retcode, "...\nTerminated."
                sys.exit()
            else:
                print "3.2. Door detector: success." ,time()  - currTime, "seconds elapsed."
             
            # Create output files
            os.chdir("detector/tools/objects_detection")
            command = "python detections_to_wnd_eval_normalized.py  -d ../../../"+dirName+"detections.data_sequence -o ../../../"+dirName+"detections_"+params.doorDetectorName+" -m ../../../"+doorDetectorModelFile 
            retcode = subprocess.call(command.split(), stdout=devnull)
            if retcode <> 0:
                print >>sys.stderr, "output file creation terminated with code", retcode, "...\nTerminated."
                sys.exit()
                
            os.chdir("../../../")
	    command = "rm "+dirName+"detections.data_sequence"
            retcode = subprocess.call(command.split())
            
        
        
        #-------------------------------------------------------------------------------------------#
        #-------------------------------------------------------------------------------------------#
        #-------------------------------------------------------------------------------------------#
        currTime = time()
        
	print "4. Running the 3Layer matlab script."
	
	os.chdir("matlab")
	command = "matlab -nodisplay -r LabelAllImages('"+dirName+"','"+params.datasetName+"','"+str(params.fold)+"');exit"
        
        retcode = subprocess.call(command.split())
        if retcode <> 0:
            print >>sys.stderr, "matlab terminated with code", retcode, "...\nTerminated."
            sys.exit()
        else:
            print "4. Success." ,time()  - currTime, "seconds elapsed."
        currTime = time()
        
  
    except OSError, e:
        print >>sys.stderr, "Execution failed:", e    

