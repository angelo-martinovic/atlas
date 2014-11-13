function TrainNN(dataset, fold, dataLocation, nClasses, nFeats)
    
    if nargin<5
        error('Usage: TrainNN(dataset, fold, dataLocation, nClasses, nFeats)');
    end
    
    nHidden = 75;

    if ~exist('tmp.mat','file')
        % -------------------------------Loading training data ---------------
        disp('Loading training data...');
        [t1,x1] = LoadData(dataset,fold,dataLocation,'train',nClasses,nFeats);
        % -------------------------------Loading validation data -------------
        disp('Loading validation data...');
        [t2,x2] = LoadData(dataset,fold,dataLocation,'valid',nClasses,nFeats);
        % -------------------------------Loading test data -------------------
        disp('Loading testing data...');
        [t3,x3] = LoadData(dataset,fold,dataLocation,'eval',nClasses,nFeats);


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

        % --------- Combining ---
        x=x';
        t = [t1 t2 t3];

        n1=length(t1);
        n2=length(t2);
        n3=length(t3);

       save('tmp.mat','t','x','n1','n2','n3','sumAll','rangeAll');
    else
       load('tmp.mat','t','x','n1','n2','n3','sumAll','rangeAll');
    end
    
    % --- Replace chimney targets with roof
    % gt = vec2ind(t);
    % gt(gt==8)=5;
    % t = ind2vec(gt);

    % Split into train, validation, test data
    [trainInd,valInd,testInd] = divideind(n1+n2+n3, 1:n1, n1+1:n1+n2, n1+n2+1:n1+n2+n3);
%     [trainInd,valInd,testInd] = divideind(n1+n2+n3, 1:100, 101:200, 201:300);
    
%     t=t(:,1:300);
%     x=x(:,1:300);

    %Feed-forward net with nHidden hidden neurons
    net = feedforwardnet(10,'trainlm');
    net.performFcn = 'mse';
%     net.trainParam.epochs = 200;
    
    net.divideFcn = 'divideind';
    net.divideParam.trainInd = trainInd;
    net.divideParam.valInd = valInd;
    net.divideParam.testInd = testInd;

    %net.layers{2}.transferFcn='purelin';

    %Train the network
    disp('Training the network...');
    tic;
    [net,tr] = train(net,x,t);
    toc;

    disp('Saving the network.');
    save([dataLocation '/output/NN_fixed_' num2str(nHidden) '-FOLD' num2str(fold) '.mat'],'net','sumAll','rangeAll');
end
