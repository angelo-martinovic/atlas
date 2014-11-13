% Type is train, valid, or eval
% [t,x] : t are target values, x are input values
function [t,x,segsPerImage,imageNames] = LoadData(dataLocation,nClasses,nFeats)

    if (nargin<3)
        error('Usage: LoadData(dataLocation,nClasses,nFeats)');
    end
    

    imageNames = dir([dataLocation '*.jpg']);
    imageNames = {imageNames.name};
    disp(imageNames);
    if (isempty(imageNames))
        t=[]; x=[];
        segsPerImage=[]; imageNames=[];
        warning('Data not found.');
        return;
    end
    
    origImageNames = strcat(dataLocation,imageNames);
    
    segFilenames = strrep(origImageNames,'.jpg','.seg');
    groundTruthFilenames = strrep(origImageNames,'.jpg','.txt');
    featureFilenames = strrep(origImageNames,'.jpg','.features.txt');
    
    allSegDistributions = zeros(0,nClasses);
    allSegs = zeros(0,nFeats);
    
    segsPerImage= cell(0);
    for i=1:length(segFilenames)
%         fprintf('.');
        %disp(['Processing image ' num2str(i) '/' num2str(length(segFilenames)) '...']);
        segmentation = dlmread(segFilenames{i});
        if exist(groundTruthFilenames{i}, 'file')
            groundTruth = dlmread(groundTruthFilenames{i});
        else
%             warning('No ground truth');
            groundTruth = zeros(size(segmentation));
        end
        features = dlmread(featureFilenames{i});
        
        if (~isequal(size(segmentation),size(groundTruth)))
            fprintf('x');
            groundTruth = imresize(groundTruth,size(segmentation),'nearest');
            fprintf('o');
        end
        
%         if strcmp(dataset,'eTrims') 
%             groundTruth=groundTruth+1;
%         end
       
        % Since segments start from 0
        segmentation = segmentation + 1;   
    
        % Number of segments in the image
        numSegs = max(segmentation(:));
        
        segDistributions = zeros(numSegs,nClasses);
        for r=1:numSegs
            res2 = groundTruth(segmentation==r);  
            label = mode(res2);
            % If label is void, use second best
            if label==0
               res2(res2==0)=[];
               label = mode(res2);
            end
            if (label>=1 && label<=nClasses)
                segDistributions(r,label)=1;
            end
        end
        allSegDistributions = [allSegDistributions; segDistributions];
        allSegs = [allSegs; features];
        segsPerImage{end+1}=numSegs;
    end
%     disp('Done');
    
    t = allSegDistributions';
    t = bsxfun(@rdivide,t,sum(t));
    clear allSegDistributions;

    x = allSegs';
    clear allSegs;
end
