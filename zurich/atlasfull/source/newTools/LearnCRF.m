function [ w ] = LearnCRF( dataset, fold, dataLocation )
    %LEARNCRF Learns the parameters of the CRF
    %   Detailed explanation goes here  
    
    if (nargin<3)
        error('Usage: LearnCRF(dataset,foldNumber,dataLocation)');
    end
    addpath /esat/sadr/amartino/Code/svm-struct-matlab-1.2
    addpath GCMex2.3
    %     randn('state',0) ;
    %     rand('state',0) ;

    %%
    % ------------------------------------------------------------------
    %                                                      Generate data
    % ------------------------------------------------------------------
    % Patterns - cell array of x - input images   
    % Labels   - cell array of y - input labelings

    
    
    % Image names
    imgNames  = ReadFoldImageNames( dataset,fold, 'valid' );
    
    indexBad = find(strcmp(imgNames,'basel_000078_mv0'));
    if ~isempty(indexBad)
        fprintf('Skipping bad image (valid).');
        imgNames = [imgNames(1:indexBad-1);imgNames(indexBad+1:end)];
    end
        
    % HACK
%     if strcmp(dataset,'eTrims')
%         nValid = length(imgNames);
%         imgNames2 = ReadFoldImageNames(dataset,fold,'train');
%         
%         indexBad = find(strcmp(imgNames2,'basel_000078_mv0'));
%         if ~isempty(indexBad)
%             fprintf('Skipping bad image (train).');
%             imgNames2 = [imgNames2(1:indexBad-1);imgNames2(indexBad+1:end)];
%         end
%     
%         imgNames = [imgNames; imgNames2];
%     end
    
%     imgNames = imgNames(1:3);
    
    % Filename stems
    origImageNames = strcat(dataLocation,imgNames);
    
    % Input images
    imageFilenames = strcat(origImageNames,'.jpg');
    
    % Load non-rectified groundtruth for etrims
    if strcmp(dataset,'eTrims')
        gtLocation = '/esat/sadr/amartino/Facades/etrims-db_v1/annotations/08_etrims-ds/';
        groundTruthFilenames = strcat(gtLocation,imgNames);
        groundTruthFilenames = strcat(groundTruthFilenames,'.txt');        
    else
        groundTruthFilenames = strcat(origImageNames,'.txt');
    end
    
    data = ['/esat/sadr/amartino/RNN/data/detLabelDistributions_' dataset '_' 'window-specific' '_fold' num2str(fold) '_winSize_200.mat'];   
    loadedData = load(data,'labelPrior');

    fprintf('Preparing data');
    patterns = cell(1,length(imgNames));
    finalLabels = cell(1,length(imgNames));
    
    nDetectors = 0;
    
    labelCost = [];
    labelCostCacheLocation = ['cache_' dataset '_train/'];
    load([labelCostCacheLocation 'fold' num2str(fold) '_labelCost.mat'],'labelCost');
%     labelCost = ones(8,8);
%     labelCost(1:9:end)=0;
    
    for imgNumber=1:length(imgNames)
        fprintf('.');
        patt = struct('img',0,'segMap',0,'detectionMaps',0,'positionMap',0,'pairwise',0,'pairwise2',0,'labelCost',0);
        
        image = imread(imageFilenames{imgNumber});
        labels = dlmread(groundTruthFilenames{imgNumber});
        
        segMap=[];
        detectionMaps=[];
        i=[];j=[];s=[];s2=[];m=[];n=[];
        
        
%         if strcmp(dataset,'eTrims') && imgNumber>nValid
%             cacheLocation = ['cache_' dataset '_train/'];
%         else
            cacheLocation = ['cache_' dataset '_valid/'];
%         end
            
        load([cacheLocation 'fold' num2str(fold) '_classification_' imgNames{imgNumber} '.mat']);
        load([cacheLocation 'fold' num2str(fold) '_detections_' imgNames{imgNumber} '.mat']);
            
        
        nDetectors = length(detectionMaps);
        nClasses = size(segMap,3);
        % For eTrims, the resulting labeling has to be 'unrectified'
        if strcmp(dataset,'eTrims') 
            homographyFilename = strcat(imageFilenames{imgNumber}(1:end-4),'rect.dat');
            homography = load(homographyFilename);

            segMapUnrect = zeros(size(labels,1),size(labels,2),nClasses);
            for i=1:nDetectors
                detectionMaps(i).detectionMapUnrect = zeros(size(labels,1),size(labels,2),nClasses);
            end
        
            for i=1:nClasses
                segMapUnrect(:,:,i)=rewarp(labels,segMap(:,:,i),homography);
                for j=1:nDetectors
                    detectionMaps(j).detectionMapUnrect(:,:,i) = rewarp(labels,detectionMaps(j).detectionMap(:,:,i),homography);
                end
            end
            segMap = segMapUnrect;
  
            for i=1:nDetectors
                detectionMaps(i).detectionMap = detectionMaps(i).detectionMapUnrect;
                detectionMaps(i).detectionMapUnrect = [];
            end
            clear segMapUnrect;

            imageUnrect = zeros(size(labels,1),size(labels,2),3);
            for i=1:3
                imageUnrect(:,:,i) = rewarp(labels,single(image(:,:,i)),homography,'linear');
            end
            image = uint8(imageUnrect);
            clear imageUnrect;
        end
        
        assert( isequal(size(segMap(:,:,1)),size(image(:,:,1))) && ...
            isequal(size(detectionMaps(1).detectionMap(:,:,1)),size(image(:,:,1))) && ...
            isequal(size(segMap(:,:,1)),size(labels)));
            
        patt.segMap=segMap;
        clear segMap;
        patt.detectionMaps = detectionMaps;
        clear detectionMaps;
    
        % Assign 0 labels to building/wall
        if strcmp(dataset,'haussmann')
            labels(labels==0)=2;
        else
            labels(labels==0)=1;
        end
          
        patt.img=image;
        patt.labelCost = labelCost;

        patt.positionMap = zeros(size(image,1),size(image,2),8);
        for l=1:8
            patt.positionMap(:,:,l) = imresize(loadedData.labelPrior(:,:,l),[size(image,1) size(image,2)],'nearest');
        end
        
        load([cacheLocation 'fold' num2str(fold) '_adjacencies_' imgNames{imgNumber} '.mat']);
        assert( m==size(image,1)*size(image,2) );
        clear image;
        
%         pairwise = sparse(i,j,s,m,n);
%         patt.pairwise = pairwise;
        
        pairwise2 = sparse(i,j,s2,m,n);
        patt.pairwise2 = pairwise2;
        clear pairwise2;

        patterns{imgNumber} = patt;
        clear patt;
        clear i; clear j; clear s; clear s2; clear m; clear n;
        
        finalLabels{imgNumber} = labels;
        clear labels;
    end
    fprintf('Done!\n');


    %%
    % ------------------------------------------------------------------
    %                                                    Run SVM struct
    % ------------------------------------------------------------------

    parm.patterns = patterns ;
    parm.labels = finalLabels ;
    parm.lossFn = @lossCB ;
    parm.constraintFn  = @constraintCB ;
    parm.featureFn = @featureCB;
    parm.dimension = 1+nDetectors+8+1;%28;   % 1 seg, nDet det, 64 labelcost
    parm.verbose = 1 ;
    model = svm_struct_learn(' -c 0.01 -o 2 -v 1 -w 4 ', parm) ;
    w = model.w ;
    
    disp(w);
    
%     save([cacheLocation 'fold' num2str(fold) '_w.mat'],'w');

end




%%
% ------------------------------------------------------------------
%                                               SVM struct callbacks
% ------------------------------------------------------------------

% Loss between the optimal labeling (y), and the proposed labeling (ybar).
% Currently implemented as the Hamming loss (percentage of mislabeled pixels)
function delta = lossCB(param, y, ybar)  
    %% Hamming loss - number of mislabeled pixels
%     delta = sum(sum(y~=ybar));% / (size(y,1)*size(y,2));

    %% Class-wise loss - number of mislabeled pixels weighted by their occurrence
    incorrMask = (y~=ybar);
    
    counts = zeros(1,8);
    incorrCounts = zeros(1,8);
    for i=1:8
        counts(i)=sum(sum(y==i));
        incorrCounts(i) = sum(y(incorrMask)==i);
    end
    totalCount = sum(counts);
    
    penalties = 1 - counts/totalCount;
    
    delta = penalties*incorrCounts';
    
    %% Pairwise loss - number of disallowed pixel changes
%     [~,indices] = GetLabelChanges(y);
%     [~,indicesbar] = GetLabelChanges(ybar);
%     
%     sameLabelIndices = 1:9:64;
%     
%     indicesSameLabel = ismember(indices,sameLabelIndices);
%     indicesBarSameLabel = ismember(indicesbar,sameLabelIndices);
% 
%     delta = delta + sum(indicesSameLabel&~indicesBarSameLabel);
    
%     uniqIndices = unique(indices);
%     counts = hist(indices,uniqIndices);
%     counts = counts(counts>0);
%     
%     countMatrix = zeros(8,8);
%     countMatrix(uniqIndices)=counts;
%     
%     disallowedChangesMask = tril(ones(8,8),-1) & countMatrix==0;
%     
%     %%
%     indices = GetLabelChanges(ybar);
%     
%     uniqIndices = unique(indices);
%     counts = hist(indices,uniqIndices);
%     counts = counts(counts>0);
%     
%     countMatrixBar = zeros(8,8);
%     countMatrixBar(uniqIndices) = counts;
%     
%     penalty = sum(countMatrixBar(disallowedChangesMask));
%     
%     delta = delta + penalty;

    
%     yValuesUniqueEncoding = yValues(:,1)*8+yValues(:,2);
%     ybarValuesUniqueEncoding = ybarValues(:,1)*8+ybarValues(:,2);
    
%     delta = delta + sum(yValuesUniqueEncoding~=ybarValuesUniqueEncoding);
    
    if param.verbose
        fprintf('delta = %3d\n', delta) ;
    end
end


%%
% Joint feature mapping of inputs and outputs - basically the "agreement"
% between inputs and labels. Implemented as the negative CRF energy.
function psi = featureCB(param, x, y)
    psi = zeros(param.dimension,1);
    height = size(y,1);
    width = size(y,2);
    
    labelCost = x.labelCost;
  
    % 1st term - unary: segment potential
    segMapLin = x.segMap(:);
    selSegMap = segMapLin((y(:)-1)*width*height+(1:width*height)');
   
    psi(1) = sum(-log(selSegMap));
   
    % Following terms - unary: detection potential
    detMaps = x.detectionMaps;
    numDetectors = length(detMaps);
    
    for i=1:numDetectors
        detMapLin = detMaps(i).detectionMap(:);
        selDetMap = detMapLin((y(:)-1)*width*height+(1:width*height)');
        
        psi(1+i) = sum(-log(selDetMap));
    end
    
   
    % 4th term - unary: position map potential
    posMapLin = x.positionMap(:);
    selPosMap = posMapLin((y(:)-1)*width*height+(1:width*height)');
    for i=1:8
        indices = (y(:)==i);
        psi(1+numDetectors+i)=sum(-log(selPosMap(indices)));
    end
    
   
%     psi(4) = sum(-log(selPosMap));
    
    % 5th term - pairwise: contrast sensitive Potts model potential
    
    % Find neighboring pixels with different labels
%     [locY_H,locX_H]=find(conv2(y,[-1 1],'valid'));
%     [locY_V,locX_V]=find(conv2(y,[-1;1],'valid'));
    [A,~] = GetLabelChanges(y,8);
    A = A.*labelCost;
    
%     labelCost = zeros(1,64);
%     labelCost(uniqIndices) = counts;
%     labelCost = 2*width*height-width-height -labelCost;
%     labelCost(1:9:end)=0;
    
    % Get the lower triangular matrix and store it into a vector

    b = A(tril(true(size(A)),-1));
    % Reverse would be:
    % A=tril(ones(8,8),0)
    % A(~~A)=b
    psi(1+numDetectors+8+1)= sum(b);
%     psi(1+numDetectors+1:1+numDetectors+28) = b;
    
    
    psi = -sparse(psi);
  if param.verbose
%        disp(full(psi'));
%     fprintf('w = psi([%8.3f,%8.3f], %3d) = [%8.3f, %8.3f]\n', ...
%             x, y, full(psi(1)), full(psi(2))) ;
  end
end

%%
function yhat = constraintCB(param, model, x, y)
% slack rescaling: argmax_y delta(yi, y) (1 + <psi(x,y), w> - <psi(x,yi), w>)
% margin rescaling: argmax_y delta(yi, y) + <psi(x,y), w>

    % Find the y which maximizes the <psi,w> + delta
    % = find the y which minimizes -<psi,w> - delta
    % = find the y which minimizes CRF energy -delta
    % = find the y which minimizes modified CRF energy
    % = GRAPHCUTS!
    
  [yhat,E_begin,E_end] = GraphCutRefinedEnergy(x,model.w,y);
  disp(model.w');
%   E_ftr = model.w'*-featureCB(param,x,yhat)-lossCB(param,y,yhat);
  
%   disp(['Graphcut: ' num2str(E_end) ',feature:' num2str(E_ftr)]);
  
  
  
%   if (E_end~=E_ftr)
%       disp('Whoa');
%   end
%   b=model.w(4:31);
%     
%   A=tril(ones(8,8),-1);
%   A(~~A)=b;
%   A = A+A';
%   figure(1);imagesc(A);colorbar;
%   colormap('hot');
%   set(gca,'YTickLabel',{'window' 'wall' 'balcony' 'door' 'roof' 'sky' 'shop' 'chimney'});
%   set(gca,'XTickLabel',{'window' 'wall' 'balcony' 'door' 'roof' 'sky' 'shop' 'chimney'});

%   pause(0.01);
%   disp(lossCB(param, y, yhat));
  
  if param.verbose
%     fprintf('yhat = violslack([%8.3f,%8.3f], [%8.3f,%8.3f], %3d) = %3d\n', ...
%             model.w, x, y, yhat) ;
  end
end

    



