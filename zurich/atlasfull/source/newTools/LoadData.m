% Type is train, valid, or eval
% [t,x] : t are target values, x are input values
function [t,x,segsPerImage,imageNames] = LoadData(dataset,fold,dataLocation,type,nClasses,nFeats)

    if (nargin<6)
        error('Usage: LoadData(dataset,fold,dataLocation,type,nClasses,nFeats)');
    end
    imageNames = ReadFoldImageNames(dataset,fold,type);
 
    if (isempty(imageNames))
        t=[]; x=[];
        segsPerImage=[]; imageNames=[];
        warning('Data not found.');
        return;
    end
    
    origImageNames = strcat(dataLocation,imageNames);
    
    segFilenames = strcat(origImageNames,'.seg');
    groundTruthFilenames = strcat(origImageNames,'.txt');
    featureFilenames = strcat(origImageNames,'.features.txt');
    
    allSegDistributions = zeros(0,nClasses);
    allSegs = zeros(0,nFeats);
    
    segsPerImage= cell(0);
    for i=1:length(segFilenames)
        fprintf('.');
        %disp(['Processing image ' num2str(i) '/' num2str(length(segFilenames)) '...']);
        segmentation = dlmread(segFilenames{i});
        if exist(groundTruthFilenames{i}, 'file')
            groundTruth = dlmread(groundTruthFilenames{i});
        else
            warning('No ground truth');
            groundTruth = zeros(size(segmentation));
        end
        features = dlmread(featureFilenames{i});
        
        if (~isequal(size(segmentation),size(groundTruth)))
            fprintf('x');
            groundTruth = imresize(groundTruth,size(segmentation),'nearest');
            fprintf('o');
        end
        
        if strcmp(dataset,'eTrims') 
            groundTruth=groundTruth+1;
        end
        
        if strcmp(dataLocation,'/esat/sadr/amartino/gould/testgpb_0.052/') || ...
            strcmp(dataLocation,'/usr/data/amartino/gould/testgpb_0.052/')
            segmentation=segmentation-1;
            features=features(2:end,:);
        end
        
        if strcmp(dataLocation,'/esat/sadr/amartino/gould/testSeeds/')|| ...
            strcmp(dataLocation,'/usr/data/amartino/gould/testSeeds/')
            if (length(unique(segmentation))~=max(segmentation(:))-min(segmentation(:))+1)
                fprintf('x');
                
                % Determine which segments are missing
                realRange = 0:size(features,1)-1;
                segUniques = unique(segmentation);
                missingSegments = find(ismember(realRange, segUniques)==0);
                %disp(missingSegments);

                % Delete the corresponding rows from the feature matrix
                features(missingSegments,:)=[];

                % Relabel the segment matrix
                for s=0:size(features,1)-1
                    segmentation(segmentation==segUniques(s+1))=s;
                end
                fprintf('o');
            end
            
        end
        
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
%             for l=1:nClasses
%                 segDistributions(r,l) = sum(sum(res2==l));
%             end
        end
        allSegDistributions = [allSegDistributions; segDistributions];
        allSegs = [allSegs; features];
        segsPerImage{end+1}=numSegs;
    end
    disp('Done');
    
%     if strcmp(type,'train') || strcmp(type,'valid')
%         allSegDistributions = allSegDistributions(sum(allSegDistributions,2)~=0,:);
%         allSegs = allSegs(sum(allSegDistributions,2)~=0,:);
%     end
    
    t = allSegDistributions';
    t = bsxfun(@rdivide,t,sum(t));
%     t(isnan(t))=0;
    clear allSegDistributions;

    x = allSegs';
    clear allSegs;
end