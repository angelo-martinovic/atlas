% This little bugger sets all the paths needed for training and evaluation.

% In your dataset folder you should have a subfolder called allInMatlab,
% and in it separate .mat files for all images.
dataFolder = ['../../data/' mainDataSet '/allInMatlab/'];

% Analysis at the end
analysisFile = '../../output/analysis.txt';
analysisFileFull = '../../output/analysisPixelAcc_RELEASE.txt';

% Segmented and colored images will go here
visuFolder = '../../output/visualization/';

% In your dataset folder you should also have files named trainList.txt and
% evalList.txt, each containing names of the images you want to use, in 
% separate lines.
dataSet = 'train';
dataSetEval = 'eval';
dataSetValid = 'valid';

trainList = readTextFile(['../../data/' mainDataSet '/' dataSet 'List' num2str(fold) '.txt']);
evalList = readTextFile(['../../data/' mainDataSet '/'  dataSetEval 'List' num2str(fold) '.txt']);
validList = readTextFile(['../../data/' mainDataSet '/'  dataSetValid 'List' num2str(fold) '.txt']);

