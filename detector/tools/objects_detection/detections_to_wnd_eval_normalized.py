#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import print_function

import sys,os
sys.path.append(os.path.dirname(os.path.realpath(__file__)) + "/..")
sys.path.append(os.path.dirname(os.path.realpath(__file__)) + "/../data_sequence")
sys.path.append(os.path.dirname(os.path.realpath(__file__)) + "/../helpers")
 
from detections_pb2 import Detections, Detection
from data_sequence import DataSequence
import get_maximum_cascade_score

import os, os.path

from optparse import OptionParser


def open_data_sequence(data_filepath):
        
    assert os.path.exists(data_filepath)
    
    the_data_sequence = DataSequence(data_filepath, Detections)
    
    def data_sequence_reader(data_sequence):    
        while True:
            data = data_sequence.read()
            if data is None:
                raise StopIteration
            else:
                yield data
    
    return data_sequence_reader(the_data_sequence)    
    

def parse_arguments():
        
    parser = OptionParser()
    parser.description = \
        "This program takes a detections.data_sequence created by ./objects_detection and converts it into the wnd_eval dataset evaluation format"

    parser.add_option("-d", "--dataSequence", dest="data_sequence_path",
                       metavar="FILE", type="string",
                       help="path to the .data_sequence file")

    parser.add_option("-m", "--trainedModel", dest="trained_model_file",
                       metavar="FILE", type="string",
                       help="path to the trained model")

    parser.add_option("-o", "--output", dest="output_path",
                       metavar="DIRECTORY", type="string",
                       help="path to a non existing directory where the wnd_eval .txt files will be created")
    parser.add_option("-s", "--scale", dest="scale",
						metavar="SCALING", type="float",
						help="scale the detections into a smaller or bigger image scale", default=1.0)
                                                  
    (options, args) = parser.parse_args()
    #print (options, args)

    if options.data_sequence_path:
        if not os.path.exists(options.data_sequence_path):
            parser.error("Could not find the data sequence")
    else:
        parser.error("'input' option is required to run this program")


    return options 



def create_wnd_eval_detections(detections_sequence, output_path, normalizationScore, scale):
    """
    """
    
    for detections in detections_sequence:
        file_path = os.path.join(output_path,  
                                     os.path.splitext(detections.image_name)[0] + ".txt")
        text_file = open(file_path, "a") # append to the file
            
        for detection in detections.detections:
			if detection.object_class != Detection.Pedestrian:
				continue

			if detection.score < 0:
				# we skip negative scores
				continue

			box = detection.bounding_box
			min_x, min_y = box.min_corner.x, box.min_corner.y
			width = box.max_corner.x - box.min_corner.x
			height = box.max_corner.y - box.min_corner.y

			adjust_width = False 
			if adjust_width:
				# in v3.0 they use 0.41 as the aspect ratio
				# before v3.0 they use 0.43 (measured in their result files)
				#aspect_ratio = 0.41
				aspect_ratio = 0.43
				center_x = (box.max_corner.x + box.min_corner.x) / 2.0
				width = height*aspect_ratio
				min_x = center_x - (width/2)

# data is [x,y,w,h, score]
			score = detection.score/normalizationScore
			detection_data = []            
			detection_data += [min_x*scale, min_y*scale]
			detection_data += [(min_x+width)*scale, (min_y+height)*scale]
			detection_data += [score]
			detection_line = " ".join([str(x) for x in detection_data]) + "\n"
			text_file.write(detection_line)
            
        text_file.close()
        print("Created file ", file_path)
        
    return

def detections_to_wnd_eval(input_path, output_path, detectorFile, scale):
    
    # get the input file
    #input_file = open(options.input_path, "r")
    detections_sequence = open_data_sequence(input_path)

    os.mkdir(output_path)    
    print("Created the directory ", output_path)
    

    normalizationScore = get_maximum_cascade_score.get_max_detector_model_score(detectorFile)
    #normalizationScore = 1
    # convert data sequence to wnd_eval data format
    create_wnd_eval_detections(detections_sequence, output_path, normalizationScore, scale)
    
    return

def main():
    
    options = parse_arguments()   
    detections_to_wnd_eval(options.data_sequence_path, options.output_path,options.trained_model_file, options.scale)
    return


if __name__ == "__main__":
        
    # Import Psyco if available
    try:
        import psyco
        psyco.full()
    except ImportError:
        #print("(psyco not found)")
        pass
    else:
        print("(using psyco)")
      
    main()






