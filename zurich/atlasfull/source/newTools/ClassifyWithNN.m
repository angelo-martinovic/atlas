function ClassifyWithNN(fold, dataLocation, nClasses, nFeats)
    
    if (nargin<4)
        error('Usage: ClassifyWithNN(fold, dataLocation, nClasses, nFeats)');
    end
    nHidden = 75;
    
    % -- Load the NN
    disp('Loading the network.');
    load([dataLocation '/output/NN_fixed_' num2str(nHidden) '-FOLD' num2str(fold) '.mat'],'net','sumAll','rangeAll');

    % -------------------------------Loading test data -------------------
    disp('Loading testing data...');
    [t,x,segsPerImage,imageNames] = LoadData(fold,dataLocation,'eval',nClasses,nFeats);
    
    % --- Scaling test data with the parameters from training&validation
    disp('Scaling data...');

    x = 2 * x';
    x = bsxfun(@minus, x, sumAll);
    x = bsxfun(@rdivide, x, rangeAll);
    
    x=x';
    
    tic;
    % Network output
    y = net(x);
    toc;
    
    % perf = perform(net,t,y)
    
    % Softmax probabilistic output
    yProb = bsxfun(@rdivide,y,sum(y));
    
    % Add a row vector of zeros at the top - class '0'
    yProb = [zeros(1,length(yProb)); yProb];
    
    % Output predictions for each image separately
    count=1;
    for i=1:length(segsPerImage)
        yProbSubset = yProb(1:nClasses+1,count:count+segsPerImage{i}-1);
        count = count+segsPerImage{i};
        
        % Create the directory if it doesnt exist
        if ~exist([dataLocation '/output/NN_fixed_fold' num2str(fold)],'dir')
            mkdir([dataLocation '/output/NN_fixed_fold' num2str(fold)]);
        end
        
        % Write out the prediction file
        dlmwrite([dataLocation '/output/NN_fixed_fold' num2str(fold) '/' imageNames{i} '.marginal.txt'],yProbSubset',' ');
        
    end
    
end