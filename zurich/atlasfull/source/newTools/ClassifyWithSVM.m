% Type has to be 'eval' or 'valid'
function ClassifyWithSVM(dataset, fold, type, dataLocation, classifier, nClasses, nFeats)
    if nargin~=7
       error('Usage: ClassifyWithSVM(dataset, fold, type, dataLocation, classifier, nClasses, nFeats)');
    end
    
    addpath /esat/sadr/amartino/Code/libsvm-3.14/matlab/
    
    % -- Load the SVM
    disp('Loading the model.');
    load([dataLocation '/output/' classifier '-FOLD' num2str(fold) '.mat'],'model','sumAll','rangeAll');

    % -- Determine class order
    [~,order] = sort(model.Label);
    
    
    % -------------------------------Loading test data -------------------
    disp(['Loading ' type ' data...']);
    if ~exist(['cache/temp_' dataset 'FOLD' num2str(fold) '_' type '.mat'],'file')
        [t3,x3,segsPerImage,imageNames] = LoadData(dataset,fold,dataLocation,type,nClasses,nFeats);
        save(['cache/temp_' dataset 'FOLD' num2str(fold) '_' type '.mat'],'t3','x3','segsPerImage','imageNames');
    else
        disp('Found cache...');
        load(['cache/temp_' dataset 'FOLD' num2str(fold) '_' type '.mat']);
    end
    
    if strcmp(type,'train')
        t=t1;
        x=x1;
    elseif strcmp(type,'valid')
        t=t2;
        x=x2;
    elseif strcmp(type,'eval')
        t=t3;
        x=x3;
    else
        error('Unsupported type');
    end
    % --- Scaling test data with the parameters from training&validation
    disp('Scaling data...');

%     maxAll = max([x],[],2)';
%     minAll = min([x],[],2)';
%     rangeAll = maxAll-minAll;
%     sumAll = maxAll+minAll;
    if size(x,1)>nFeats
        x=x(1:nFeats,:);
    end
    x = 2 * x';
    x = bsxfun(@minus, x, sumAll);
    x = bsxfun(@rdivide, x, rangeAll);
    
    % Target classes
    t = (vec2ind(t))';
    
    if strcmp(dataset,'eTrims')
        t=t-1;
    end
    
    % SVM output
    disp('Predicting output...');
    if ~exist(['cache/temp_' dataset 'FOLD' num2str(fold) '_' type '_prediction_' classifier '.mat'],'file')
        tic;
        [predict_label, accuracy, yProb] = svmpredict(t,x,model,'-b 1');
        toc;
        save(['cache/temp_' dataset 'FOLD' num2str(fold) '_' type '_prediction_' classifier '.mat'],'predict_label','accuracy','yProb');
    else
        disp('Found cache...');
        load(['cache/temp_' dataset 'FOLD' num2str(fold) '_' type '_prediction_' classifier '.mat']);
    end
   
    
    
    % -- Transpose the probability matrix to have rows corresponding to
    % classes, and reorder the rows based on the model
    yProb = yProb';
    yProb = yProb(order,:);
    
    % Add a row vector of zeros at the top - class '0'
    yProb = [zeros(1,size(yProb,2)); yProb;zeros(1,size(yProb,2));];
    
    
    % Output predictions for each image separately
    count=1;
    for i=1:length(segsPerImage)
        yProbSubset = yProb(1:nClasses+1,count:count+segsPerImage{i}-1);
        count = count+segsPerImage{i};
        
        % Create the directory if it doesnt exist
        if ~exist([dataLocation '/output/' classifier '_fold' num2str(fold)],'dir')
            mkdir([dataLocation '/output/' classifier '_fold' num2str(fold)]);
        end
        
        % Write out the prediction file
        dlmwrite([dataLocation '/output/' classifier '_fold' num2str(fold) '/' imageNames{i} '.marginal.txt'],yProbSubset',' ');
        
    end
    
end