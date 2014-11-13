function [accuracies, confusionMatrices] = findParameters(fold)

accuracies = [];
confusionMatrices = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load data and parameters if they aren't already loaded
if ~exist('Wbot','var')
    %fullTrainParamName = '../output/fullParams_hid50_PTC5e-05_zeroW35maxIterPT400_fullC0.001_L0.05maxIter150_CUT1_78.1.mat'
    fullTrainParamName = ['../output/haussmannFinal_fullParams_hid50_PTC0.0001_fullC0.0001_L0.05_FOLD' num2str(fold) '.mat'];    
   % fullTrainParamName = '../output/haussmannNewLabels_fullParams_hid50_PTC0.0001_fullC0.0001_L0.05.mat'; 
   load(fullTrainParamName,'Wbot','W','Wout','Wcat','params')
end

if ~exist('validSet','var')
    mainDataSet = 'haussmannFinal';% mainDataSet = 'iccv09-1';
    neighNameStem = ['../data/' mainDataSet '-FOLD' num2str(fold)];
    dataSetEval = 'valid';
    neighNameEval = [neighNameStem '_' dataSetEval '.mat'];
    
    evalSet=load(neighNameEval,'allData' );
    analysisFileFull = '../output/analysisPixelAcc_RELEASE.txt';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%for alpha1=0.5:0.25:3.5
    %for alpha2=4.0:6.0:10.0
      %  for lambda=0.5:1:10.5   
     for peakH = 0.15:0.1:0.15
         for peakV = 0.2:0.1:0.2
            alpha1=0.75;
            lambda = 6.5;
            alpha2 = 7;
            hyperParams = [alpha1 alpha2 lambda peakH peakV];
            %Run the testing on evalSet
            [allResultsTEST outString confusionMatrix accuracy] = labelImagePixels(evalSet.allData,Wbot,W,Wout,Wcat,params,fold,hyperParams);
            accuracies = [accuracies; accuracy];
            %disp(hyperParams);
            %disp(confusionMatrix);
            disp(accuracy);
            %disp(alpha2);
            confusionMatrices = [confusionMatrices; confusionMatrix];
            
        end
    end
%end

save(['confMatrices' num2str(fold) '.mat'],'confusionMatrices');
save(['accuracies' num2str(fold) '.mat'],'accuracies');






end