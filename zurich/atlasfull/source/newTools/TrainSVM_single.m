function TrainSVM_single(dataset,fold, dataLocation, nClasses, nFeats,log2c,log2g,maxTrainExamples,svmName)
    if nargin<8
        disp('Usage: TrainSVM_single(dataset,fold, dataLocation, nClasses, nFeats,log2c,log2g,maxTrainExamples,svmName)')
        return
    end 
    if nargin<9
        svmName = 'SVM_cv';
    end
    
    if isdeployed
     	fold = str2double(fold);
        nClasses = str2double(nClasses);
        nFeats = str2double(nFeats);
        log2c = str2double(log2c);
        log2g = str2double(log2g);
        maxTrainExamples = str2double(maxTrainExamples);
    else
        addpath /esat/sadr/amartino/Code/libsvm-3.14/matlab/;
    end

    % -------------------------------Loading training data ---------------
    disp('Loading training data...');
    if ~exist(['cache/temp_' dataset 'FOLD' num2str(fold) '_train.mat'],'file')
        [t1,x1,segsPerImage,imageNames] = LoadData(dataset,fold,dataLocation,'train',nClasses,nFeats);
        save(['cache/temp_' dataset 'FOLD' num2str(fold) '_train.mat'],'t1','x1','segsPerImage','imageNames');
    else
        disp('Found cache...');
        load(['cache/temp_' dataset 'FOLD' num2str(fold) '_train.mat']);
    end
    
    
    % -------------------------------Loading validation data -------------
    disp('Loading validation data...');
    if ~exist(['cache/temp_' dataset 'FOLD' num2str(fold) '_valid.mat'],'file')
        [t2,x2,segsPerImage,imageNames] = LoadData(dataset,fold,dataLocation,'valid',nClasses,nFeats);
        save(['cache/temp_' dataset 'FOLD' num2str(fold) '_valid.mat'],'t2','x2','segsPerImage','imageNames');
    else
        disp('Found cache...');
        load(['cache/temp_' dataset 'FOLD' num2str(fold) '_valid.mat']);
    end

    % -------------------------------Loading test data -------------------
    disp('Loading testing data...');
    if ~exist(['cache/temp_' dataset 'FOLD' num2str(fold) '_eval.mat'],'file')
        [t3,x3,segsPerImage,imageNames] = LoadData(dataset,fold,dataLocation,'eval',nClasses,nFeats);
        save(['cache/temp_' dataset 'FOLD' num2str(fold) '_eval.mat'],'t3','x3','segsPerImage','imageNames');
    else
        disp('Found cache...');
        load(['cache/temp_' dataset 'FOLD' num2str(fold) '_eval.mat']);
    end

   
    % --------- Combining ---

    % Eliminate 0-labels
    tv = (vec2ind(t1))';tv( isnan(sum(t1)) ) = 0;t1 = tv(tv~=0);x1 = x1(:,tv~=0);
    tv = (vec2ind(t2))';tv( isnan(sum(t2)) ) = 0;t2 = tv(tv~=0);x2 = x2(:,tv~=0);
    tv = (vec2ind(t3))';tv( isnan(sum(t3)) ) = 0;t3 = tv(tv~=0);x3 = x3(:,tv~=0);
    
    % No depth info
    if strcmpi(svmName,'svm_noDepth')
        x1 = x1(1:end-1,:);
        x2 = x2(1:end-1,:);
        x3 = x3(1:end-1,:);
    end
    
    % --------- Data scaling ---
    disp('Scaling data...');
    maxAll = max([x1 x2],[],2)';
    minAll = min([x1 x2],[],2)';
    rangeAll = maxAll-minAll;
    sumAll = maxAll+minAll;

    % Scale to [-1,1]
    x = [x1 x2 x3]';
    
    x = 2 * x;
    x = bsxfun(@minus, x, sumAll);
    x = bsxfun(@rdivide, x, rangeAll);
    
    
    t = [t1;t2;t3];
       
    n1=length(t1);
    n2=length(t2);
    n3=length(t3);
   
    tic;
    
    % Output the data
%     location = '/usr/data/amartino/Code/libsvm-3.14/';
%     trainFilename = strcat(location,'train.dat');
%     validFilename = strcat(location,'valid.dat');
%     evalFilename = strcat(location,'eval.dat');
    
%     fileID = fopen(trainFilename,'w'); 
%     for i=1:n1
%         fprintf(fileID,'%d ',t(i));
%         for j=1:nFeats
%             fprintf(fileID,'%d:%f ',j,x(i,j));
%         end
%         fprintf(fileID,'\n');
%     end
%     fclose(fileID);
%     
%     fileID = fopen(evalFilename,'w'); 
%     for i=n1+n2+1:n1+n2+n3
%         fprintf(fileID,'%d ',t(i));
%         for j=1:nFeats
%             fprintf(fileID,'%d:%f ',j,x(i,j));
%         end
%         fprintf(fileID,'\n');
%     end
%     fclose(fileID);
    
%     disp('Starting the crossvalidation...');
%     
%     bestcv = 0;
%     for log2c = -1:3,
%       for log2g = -4:1,
%           fprintf('Arguments = eTrims %d %d %d\nQueue\n\n',1,log2c,log2g);
%       end
%     end
%     trainExamples = min(maxTrainExamples,n1+n2);
%     cmd = ['-v 5 -c ', num2str(2.^log2c), ' -g ', num2str(2.^log2g),' -t 2 -m 2000 -b 1 -q'];
%     cv = svmtrain(t(1:trainExamples),x(1:trainExamples,1:end),cmd);
%     if (cv >= bestcv),
%       bestcv = cv; bestc = 2.^log2c; bestg = 2.^log2g;
%     end
%     fprintf('%g %g %g (best c=%g, g=%g, rate=%g)\n', log2c, log2g, cv, bestc, bestg, bestcv);

  

    % Train with only the training data: n1 observations
    disp('Starting the SVM training...');
    trainExamples = min(maxTrainExamples,n1);
    model = svmtrain(t(1:trainExamples),x(1:trainExamples,1:end),['-s 0 -t 2 -c ', num2str(2.^log2c), ' -g ', num2str(2.^log2g),' -m 2000 -h 0 -b 1']);
    toc;
  
%     % Prediction on the train set
%     disp('Predicting performance on train...');
%     tic;
%     [predict_label, accuracy, prob_estimates] = svmpredict(t(1:n1), x(1:n1,1:end), model,'-b 1');
%     disp(['Accuracy on the training set: ' num2str(accuracy(1))]);
%     toc;
    
    
    % Prediction on the test set
    disp('Predicting performance on test...');
    tic;
    [predict_label, accuracy, prob_estimates] = svmpredict(t(n1+n2+1:n1+n2+n3), x(n1+n2+1:n1+n2+n3,1:end), model,'-b 1');
    disp(['Accuracy on the test set: ' num2str(accuracy(1))]);
    toc;
%     
%     
    disp('Saving the SVM model.');
    save([dataLocation '/output/' svmName '-FOLD' num2str(fold) '.mat'],'model','sumAll','rangeAll');   
end
