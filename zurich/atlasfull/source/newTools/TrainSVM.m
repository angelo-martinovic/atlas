function TrainSVM(dataset,fold, dataLocation, nClasses, nFeats,log2c,log2g,maxTrainExamples)
    if nargin~=8
        disp('Usage: TrainSVM(dataset,fold, dataLocation, nClasses, nFeats,log2c,log2g,maxTrainExamples)')
        return
    end 
    
    if isdeployed
     	fold = str2double(fold);
        nClasses = str2double(nClasses);
        nFeats = str2double(nFeats);
        log2c = str2double(log2c);
        log2g = str2double(log2g);
        maxTrainExamples = str2double(maxTrainExamples);
    end

    %if ~exist(['temp_' dataset 'FOLD' num2str(fold) '.mat'],'file')
        % -------------------------------Loading training data ---------------
        disp('Loading training data...');
        [t1,x1] = LoadData(dataset,fold,dataLocation,'train',nClasses,nFeats);
        % -------------------------------Loading validation data -------------
        disp('Loading validation data...');
        [t2,x2] = LoadData(dataset,fold,dataLocation,'valid',nClasses,nFeats);
        % -------------------------------Loading test data -------------------
        disp('Loading testing data...');
        [t3,x3] = LoadData(dataset,fold,dataLocation,'eval',nClasses,nFeats);

     %   save(['temp_' dataset 'FOLD' num2str(fold) '.mat'],'t1','x1','t2','x2','t3','x3');
    %else
     %   load(['temp_' dataset 'FOLD' num2str(fold) '.mat']);
    %end
    
    % --------- Data scaling ---
    disp('Scaling data...');
    maxAll = max([x1],[],2)';
    minAll = min([x1],[],2)';
    rangeAll = maxAll-minAll;
    sumAll = maxAll+minAll;

    % Scale to [-1,1]
    x = [x1 x2 x3]';
    
    x = 2 * x;
    x = bsxfun(@minus, x, sumAll);
    x = bsxfun(@rdivide, x, rangeAll);
    
    % --------- Combining ---

    t = [t1 t2 t3];
       
    n1=length(t1);
    n2=length(t2);
    n3=length(t3);

    % Target classes
    t = (vec2ind(t))';
   
    disp('Starting the training...');
    tic;
    bestcv = 0;
%     for log2c = -1:3,
%       for log2g = -4:1,
%           fprintf('Arguments = eTrims %d %d %d\nQueue\n\n',1,log2c,log2g);
%       end
%     end
    trainExamples = min(maxTrainExamples,n1);
    cmd = ['-c ', num2str(2.^log2c), ' -g ', num2str(2.^log2g),' -t 2 -m 2000 -h 0 -b 1 -q'];
    model = svmtrain(t(1:trainExamples),x(1:trainExamples,1:end),cmd);
    disp('Predicting on validation set...');
    [~, cv, ~] = svmpredict(t(n1+1:n1+n2), x(n1+1:n1+n2,1:end), model,'-b 1');
%     if (cv >= bestcv),
%       bestcv = cv; bestc = 2.^log2c; bestg = 2.^log2g;
%     end
    fprintf('%g %g %g\n', log2c, log2g, cv(1));

    toc;

    % Train with only the training data: n1 observations
%     disp('Starting the SVM training...');
    
%     model = svmtrain(t(1:n1),x(1:n1,1:end),'-s 0 -c 4 -t 2 -g 0.125 -m 2000 -h 0 -b 1');
   
  
    
    return;
    % Prediction on the validation set
%     disp('Predicting performance on test...');
%     [predict_label, accuracy, prob_estimates] = svmpredict(t(n1+n2+1:n1+n2+n3), x(n1+n2+1:n1+n2+n3,1:end), model);
%     disp(['Accuracy on the test set: ' num2str(accuracy(1))]);
%     
%     
%     disp('Saving the SVM model.');
%     save([dataLocation '/output/SVM-FOLD' num2str(fold) '.mat'],'model','sumAll','rangeAll');   
end
