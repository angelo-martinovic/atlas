% type is either 'eval' or 'valid'
function [results,confMatrices] = testVRNN(fold, type, nImages)

if nargin<3
    disp('Usage: testVRNN(foldNumber, {eval/valid}, nImages)');
    return;
end

% addpath /esat/sadr/amartino/Code/FS-MKLR/
% addpath /esat/sadr/amartino/Code/libsvm-3.14/matlab/
addpath newTools/

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load data and parameters if they aren't already loaded
if ~exist('Wbot','var')
%fullTrainParamName = '../output/fullParams_hid50_PTC5e-05_zeroW35maxIterPT400_fullC0.001_L0.05maxIter150_CUT1_78.1.mat'
fullTrainParamName = ['../../output/haussmannFinal_fullParams_hid50_PTC0.0001_fullC0.0001_L0.05_FOLD' num2str(fold) '.mat'];    
%fullTrainParamName = ['../../output/haussmanngpb_fullParams_hid50_PTC0.0001_fullC0.0001_L0.05_FOLD' num2str(fold) '.mat'];    
%fullTrainParamName = ['../../output/eTrims_fullParams_hid50_PTC0.0001_fullC0.0001_L0.05_FOLD' num2str(fold) '.mat'];  
%fullTrainParamName = '../output/haussmannNewLabels_fullParams_hid50_PTC0.0001_fullC0.0001_L0.05.mat'; 
%fullTrainParamName = '../../output/iccv09-1_fullParams_hid50_PTC0.0001_fullC0.0001_L0.05_good.mat'; 
   load(fullTrainParamName,'Wbot','W','Wout','Wcat','params')
end

if ~exist('evalSet','var')
%     mainDataSet = 'iccv09-1';
     mainDataSet = 'haussmannFinal'; 
    neighNameStem = ['../../data/' mainDataSet '-FOLD' num2str(fold)];
    dataSetEval = type;
    neighNameEval = [neighNameStem '_' dataSetEval '.mat'];
    
    evalSet=load(neighNameEval,'allData' );
%     evalSet = load('../../data/iccv09-1-allNeighborPairs_eval.mat');
    analysisFileFull = '../../output/analysisPixelAcc_RELEASE.txt';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Run the testing on evalSet
% hyperParameters = [0.75 0.1 0.00001 6.5 0.15 0.2]; %eTrims params
% hyperParameters = [0.75 7 0.01 6.5 5]; %1-Window 2-Door 3-Position 4-Lambda 5,6-RegionCRF
% hyperParameters = [4 7 0.01 6.5 5]; %1-Window 2-Door 3-Position 4-Lambda 5,6-RegionCRF

hyperParameters = struct('alphaWin',0,'alphaDoor',0,'alphaPos',0,'lambda',0,'lambda2',0,'imgNames',0,'labelMaps',0,'labelPrior',0,'type',type);

% Image names
evalFilename = ['/esat/sadr/amartino/RNN/data/haussmannFinal/' type 'List' num2str(fold) '.txt'];
delimiter = '';
formatSpec = '%s%[^\n\r]';
fileID = fopen(evalFilename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
fclose(fileID);
hyperParameters.imgNames = [dataArray{:,1:end-1}];
clear dataArray;

%STATISTICS from the validation set
%data = ['../../data/eTrims-FOLD' num2str(fold) '_train.mat'];
 data = ['../../data/detLabelDistributions_haussmann_valid_fold' num2str(fold) '_winSize_200.mat'];   
loadedData = load(data,'labelMaps','labelPrior');

% Detection label distribution prior
hyperParameters.labelMaps = loadedData.labelMaps;

% General label distribution prior
hyperParameters.labelPrior = loadedData.labelPrior;
clear loadedData;

% alphaWinRange = [1 3 5];    %5
% alphaDoorRange = [3 7 11];  %11
% alphaPositionRange = [1 3]; %1
% lambdaRange = [6 11 16];    %16
% lambda2Range = [5 9 13];    %5

% alphaWinRange = [0.1380];    %5
% alphaDoorRange = [0.5625];  %11
% alphaPositionRange = [0]; %1
% lambdaRange = [16];    %16
% lambda2Range = [5];    %5



% results = zeros(length(alphaWinRange),length(alphaDoorRange),length(alphaPositionRange),length(lambdaRange),length(lambda2Range));
% confMatrices = cell(length(alphaWinRange),length(alphaDoorRange),length(alphaPositionRange),length(lambdaRange),length(lambda2Range));
% matlabpool open 2
tic;
% for i=1:length(alphaWinRange)
%     for j=1:length(alphaDoorRange)
%         for k=1:length(alphaPositionRange)
%             for l=1:length(lambdaRange)
%                 for m=1:length(lambdaRange)

% Old parameters for gould CRF
w =[ 0.1380    0.5626    2.0671    1.9670;
     0.1499    0.5429    2.2373    1.6980; 
     0.1241    0.4628    1.5121    1.8575;
     0.1515    0.5499    1.3159    2.1810;
     0.1757    0.6434    1.6991    1.8439;
    ];    

% New parameters for SVM
% w =[ 
%     0.3693     0.5145    1.1940    1.9430;
%     0.3553     0.5739    1.3092    2.1817;
%     0.3474     0.4365    1.0365    2.1025;
%     0.3684     0.5400    1.1337    2.1717;
%     0.3590     0.5922    1.2798    1.9562
%  ];      

hyperParameters.w=w(fold,:);

disp(hyperParameters);
[allResultsTEST outString confusionMatrix acc] = labelImagePixels(evalSet.allData,Wbot,W,Wout,Wcat,params,fold,hyperParameters,nImages);
% results(i,j,k,l,m) = acc;
% confMatrices{i,j,k,l,m} = confusionMatrix;
%                 end
%             end
% Confusion matrix 
disp(acc);
disp('Confusion matrix');
confusionMatrix(isnan(confusionMatrix))=0;
disp(100*confusionMatrix);
%         end
%             
%     end
% end
toc;
% save(['crossValid_' num2str(fold) '.mat'],'confMatrices','results');
% matlabpool close

% [allResultsTEST outString confusionMatrix acc] = labelImagePixels(evalSet.allData,Wbot,W,Wout,Wcat,params,fold,hyperParameters,nImages);

% disp(results);
% analysis output
% Confusion matrix 
% disp(acc);
% disp('Confusion matrix');
% disp(uint8(100*confusionMatrix));
% dlmwrite('confMatFull.txt',uint8(100*confusionMatrix));

% Parameters of the evaluation: dataset, size of semantic vectors,
% regularization parameters and the calculated norm of matrix W
% analOutBegin=sprintf('Full:%s\t%i\tPTC:%f\tC:%f\t%f\t%f', mainDataSet,params.numHid,params.regPTC,params.regC,params.LossPerError,norm(W));
% + Pixel classification score
% analOut=sprintf('%s\t%s\n',analOutBegin, outString);
% disp(analOut)
% fid = fopen(analysisFileFull,'a');
% fprintf(fid,'%s',analOut);
% fclose(fid);
end
