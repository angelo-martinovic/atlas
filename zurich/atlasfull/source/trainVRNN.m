%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright by Richard Socher
% For questions, email richard @ socher .org
% Modifications and helpful comments by Angelo Martinovic
% For questions, ask Rodrigo. That usually helps.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function train = trainVRNN(dataset,semVecSize, fold)
    disp(['Size of hidden layer vectors: ',num2str(semVecSize)]);
    addpath(genpath('tools/'));

  %  LASTN = maxNumCompThreads(8);
    %%%%%%%%%%%%%%%%%%%%%%
    % data set: stanford background data set from Gould et al.
    %mainDataSet = 'iccv09-1'
    % Main data set that you wish to use. This corresponds to the folder
    % name in data/ folder.
    mainDataSet = dataset
    setDataFolders

    %%%%%%%%%%%%%%%%%%%%%%%
    % minfunc options (not tuned)
    options.Method = 'lbfgs';   %Optimization method
    options.MaxIter = 1000;  %default = 1000 - maximum number of iterations
    optionsPT=options;      %optionsPT is used for the first optimization, options for the second
    options.TolX = 1e-4;    %default = 1e-4 - minimum step size, the lower the better


    %This thing will save your life.
    set(0,'RecursionLimit',10000);
    
    %%%%%%%%%%%%%%%%%%%%%%%
    %iccv09: 0 void   1,1 sky  0,2 tree   2,3 road  1,4 grass  1,5 water  1,6 building  2,7 mountain 2,8 foreground
    %haussmann 0 outlier, 1 window, 2 wall, 3 balcony, 4 door, 5 roof, 6 sky, 7 shop, 8 chimney
    params.numLabels = 9; % we never predict 0 (void) - number of different labels, you should label outliers as 0
    %params.numFeat = 119;
    params.numFeat = 225;   %Number of features for each segment.


    %%%%%%%%%%%%%%%%%%%%%%
    % model parameters(should be ok,found via CV)-crossvalidation
    params.numHid = semVecSize; %Size of hidden vectors
    params.regPTC = 0.0001;     %Regularization parameter
    params.regC = params.regPTC;%It appears there are two...
    params.LossPerError = 0.05; %Penalization term for incorrect decisions

    %%%%%%%%%%%%%%%%%%%%%%
    % input and output file names
    neighNameStem = ['../../data/' mainDataSet '-FOLD' num2str(fold)];   %../data/haussmann-FOLD1
    neighName = [neighNameStem '_' dataSet '.mat'];                 %../data/haussmann-FOLD1_train.mat
    neighNameEval = [neighNameStem '_' dataSetEval '.mat'];         %../data/haussmann-FOLD1_eval.mat
    neighNameValid = [neighNameStem '_' dataSetValid '.mat'];         %../data/haussmann-FOLD1_valid.mat

    paramString = ['_hid' num2str(params.numHid ) '_PTC' num2str(params.regPTC)];  %_hid50_PTC0.0001
    fullParamNameBegin = ['../../output/' mainDataSet '_fullParams'];                                  %../output/hausmann_fullParams
    paramString = [paramString '_fullC' num2str(params.regC) '_L' num2str(params.LossPerError) '_FOLD' num2str(fold)];    %_hid50_PTC0.0001_FOLD1_fullC0.0001_L0.05_FOLD1
    fullTrainParamName = [fullParamNameBegin paramString '.mat'];                                   %../output/hausmann_fullParams_hid50_PTC0.0001_fullC0.0001_L0.05_FOLD1.mat
    fullTrainParamNameTemp = [fullParamNameBegin paramString '_temp.mat'];                          %../output/hausmann_fullParams_hid50_PTC0.0001_fullC0.0001_L0.05_FOLD1_temp.mat

    disp(['fullTrainParamName=' fullTrainParamName ])

    disp('All parameters loaded. Checking for prepared data...');
    
    %%%%%%%%%%%%%%%%%%%%%%
    % load and pre-process training and testing dataset
    % If the neighbor pair file does not exist
    if ~exist(neighName,'file')
        disp('Train data not prepared. Preparing the data...');
        %%% first run preProData once for both train and eval!
        dataSet='train';
        preProSegFeatsAndSave(dataFolder,neighNameStem,trainList, neighName, dataSet, params, mainDataSet)
    end
    
    if ~exist(neighNameEval,'file') 
        disp('Eval data not prepared. Preparing the data...');
        dataSet='eval';
        preProSegFeatsAndSave(dataFolder,neighNameStem,evalList, neighNameEval, dataSet, params, mainDataSet)
    end
    
    if ~exist(neighNameValid,'file')
        disp('Valid data not prepared. Preparing the data...');
        dataSet='valid';
        preProSegFeatsAndSave(dataFolder,neighNameStem,validList, neighNameValid, dataSet, params, mainDataSet)
        
    end
    disp('Finished preparing the data.');

    %return;
    disp('Loading the training set...');
    if ~exist('allData','var')
        load(neighName,'allData','goodPairsL','goodPairsR','badPairsL','badPairsR','onlyGoodL','onlyGoodR','onlyGoodLabels','onlyGoodDistributions','allSegs','allSegLabels','allSegDistributions');
        %evalSet=load(neighNameEval,'allData','goodPairsL','goodPairsR','badPairsL','badPairsR','onlyGoodL','onlyGoodR','onlyGoodLabels','allSegs','allSegLabels'); 
    end
    disp('Loaded the training set.');

     %start a matlab pool to use all CPU cores for full tree training
%     if isunix && matlabpool('size') == 0
%        numCores = feature('numCores')
%        if numCores>8
%           numCores=8
%        end
%        matlabpool('open',numCores);
%     end
 disp('Checking if first part of training was finished...');
if ~exist(fullTrainParamNameTemp,'file')
     disp('It was not. Starting the pretraining...');
    %%%%%%%%%%%%%%%%%%%%%%
    % initialize parameters
    initParams

    %%%%%%%%%%%%%%%%%%%%%%
    % TRAINING

    % train Wbot layer and first RNN collapsing decisions with all possible correct and incorrect segment pairs
    % this uses the training data more efficiently than the purely greedy full parser training that only looks at some pairs
    % both could have been combined into one training as well.
    
    %Pushes the parameters onto the stack - X is the data, decodeInfo matrix sizes
    [X decodeInfo] = param2stack(Wbot,W,Wout,Wcat);
    %Calls the minimization with the cost function costFctInitWithCat
    X = minFunc(@costFctInitWithCat,X,optionsPT,decodeInfo,goodPairsL,goodPairsR,badPairsL,badPairsR,onlyGoodL,onlyGoodR,onlyGoodLabels,onlyGoodDistributions,allSegs,allSegLabels,allSegDistributions,params);
    [Wbot,W,Wout,Wcat] = stack2param(X, decodeInfo);
    disp('Done with pretraining. Saving the output...');
    save(fullTrainParamNameTemp,'Wbot','W','Wout','Wcat','params','options','-v7.3');
    disp('Output saved.');
else
     disp('Indeed. Loading the computed parameters...');
    load(fullTrainParamNameTemp,'Wbot','W','Wout','Wcat','params');
end
     
%      %This thing will save your life.
    set(0,'RecursionLimit',10000);
    [X decodeInfo] = param2stack(Wbot,W,Wout,Wcat);
    %Calls the minimization with the cost function costFctFull
    disp('Starting the full training...');
    X = minFunc(@costFctFull,X,options,decodeInfo,allData,params);
    %Pop the parameters from stack
    [Wbot,W,Wout,Wcat] = stack2param(X, decodeInfo);
    
     disp('Training finished. Saving the output...');
    %Save the estimated parameters in a .mat file.
    save(fullTrainParamName,'Wbot','W','Wout','Wcat','params','options','-v7.3');
     disp('Output saved. Starting the testing phase...');

    %%%%%%%%%%%%%%%%%%%%%
    % run analysis
    % testVRNN

    % visualize trees
    disp('Ready for visualization.');
    % visualizeImageTrees
end   



