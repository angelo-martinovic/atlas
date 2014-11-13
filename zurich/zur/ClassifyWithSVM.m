% Type has to be 'eval' or 'valid'
function ClassifyWithSVM( dataLocation, classifierLocation)
    if nargin~=2
       error('Usage: ClassifyWithSVM(dataLocation, classifierLocation)');
    end
    
    addpath ../libsvm-3.14/matlab/
    
    disp('BOTTOM LAYER');
    % -- Load the SVM
    disp('--Loading the classifier model...');
    load(classifierLocation,'model','sumAll','rangeAll');

    nClasses = model.nr_class;
    nFeats = size(model.SVs,2);
    % -- Determine class order
    [~,order] = sort(model.Label);
    
    % -------------------------------Loading test data -------------------
    disp('--Loading image data...');
    [t,x,segsPerImage,imageNames] = LoadData(dataLocation,nClasses,nFeats);
       
    % --- Scaling test data with the parameters from training&validation
    fprintf('\n--Scaling data...\n');

    if size(x,1)>nFeats
        x=x(1:nFeats,:);
    end
    x = 2 * x';
    x = bsxfun(@minus, x, sumAll);
    x = bsxfun(@rdivide, x, rangeAll);
    
    % Target classes
    t = (vec2ind(t))';
    
%     if strcmp(dataset,'eTrims')
%         t=t-1;
%     end
    
    % SVM output
    disp('--Running classification...');

    [~, ~, yProb] = svmpredict(t,x,model,'-b 1 -q');

       
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
        
        % Write out the prediction file
        dlmwrite([dataLocation imageNames{i}(1:end-4) '.marginal.txt'],yProbSubset',' ');
        
    end
    disp('--Classification done.');
end