function CreateSocherMatFiles(path)
    filenames=dir([path '*.jpg']);

    for i=1:size(filenames,1)
        inputFilename = filenames(i).name;
        stem = [path inputFilename(1:end-4)];

        img =       imread([stem '.jpg']);
        labels =    load([stem '.txt']);
        segs2 =     load([stem '.seg']);
        feat2 =     load([stem '.features.txt']);
        
        if strcmp(path,'/esat/sadr/amartino/gould/testgpb_0.052/')
            segs2=segs2-1;
            feat2=feat2(2:end,:);
        end
        
        if strcmp(path,'/esat/sadr/amartino/gould/testSeeds/')
            if (length(unique(segs2))~=max(segs2(:))-min(segs2(:))+1)
                disp(['Missing segments in image ' num2str(i)]);
                
                % Determine which segments are missing
                realRange = 0:size(feat2,1)-1;
                segUniques = unique(segs2);
                missingSegments = find(ismember(realRange, segUniques)==0);
                disp(missingSegments);

                % Delete the corresponding rows from the feature matrix
                feat2(missingSegments,:)=[];

                % Relabel the segment matrix
                for s=0:size(feat2,1)-1
                    segs2(segs2==segUniques(s+1))=s;
                end
                disp(['Fixed image ' num2str(i)]);
            end
            
        end
        
        

        %Generic window detector
%         detections = load([stem '.detections.txt']);
% 
%         %Generic door detector
%         detections2 = [];
%         if exist([stem '.detections2.txt'],'file')
%             detections2 = load([stem '.detections2.txt']);
%         end
% 
%         %Specific window detector
%         detectionsTest = [];
%         detectionsValid = [];
%         if exist(['detectionsWindowSpecific/test/' stem '.txt'],'file')
%             detectionsTest = load(['detectionsWindowSpecific/test/' stem '.txt']);
%         end
%         if exist(['detectionsWindowSpecific/valid/' stem '.txt'],'file')
%             detectionsValid = load(['detectionsWindowSpecific/valid/' stem '.txt']);
%         end
% 
% 
%         %Specific door detector
%         detectionsTest2 = [];
%         detectionsValid2 = [];
%        if exist(['detectionsDoorSpecific/test/' stem '.txt'],'file')
%             detectionsTest2 = load(['detectionsDoorSpecific/test/' stem '.txt']);
%        end
%        if exist(['detectionsDoorSpecific/valid/' stem '.txt'],'file')
%             detectionsValid2 = load(['detectionsDoorSpecific/valid/' stem '.txt']);
%        end


        save([stem '.mat'],'img','labels','segs2','feat2');
%         'detections','detections2','detectionsTest','detectionsTest2','detectionsValid','detectionsValid2');
        disp(['Processed image ',num2str(i),'/',num2str(size(filenames,1)),'.']);
    end

end
