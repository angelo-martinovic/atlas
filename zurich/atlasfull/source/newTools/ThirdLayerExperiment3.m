function ThirdLayerExperiment2(img)
%     for img=1:1

        %% Load the 2nd layer output
        load(['/esat/sadr/amartino/RNN/repo/source/markus_journal/markus_haussmann_eval_fold'...
            '_1_img_' num2str(img) '.mat'], 'outImg','sgmp');

        resultImg = zeros(size(outImg));
        %% Vertical region order
        [i,~]=find(outImg==2);
        upWall = min(i); botWall  = max(i);

        [i,~]=find(outImg==5);
        upRoof = min(i); botRoof  = max(i);

        [i,~]=find(outImg==6);
        botSky  = max(i);

        [i,~]=find(outImg==7);
        upShop = min(i);

        wallRoofBoundary = botRoof;%round((upWall+botRoof)/2);
        roofSkyBoundary = upRoof;%round((upRoof+botSky)/2);
        shopWallBoundary = upShop;%round((upShop+botWall)/2);

        resultImg(1:roofSkyBoundary,:)=6;
        resultImg(roofSkyBoundary+1:wallRoofBoundary,:)=5;
        resultImg(wallRoofBoundary+1:shopWallBoundary,:)=2;
        resultImg(shopWallBoundary+1:end,:)=7;

        %% Extract objects
        fig=figure(1);imagesc(outImg);
        set(fig,'Position',[500 200 400 400])

        objectList =  struct('objID',{},'objClass',{},'bbox',{});
        objectGroupList = struct('objClass',{},'groupIDs',{});
        locationLUT = zeros(size(outImg));
        objID=0;
 
        for label = [1 3 4]
            objectCCP = bwconncomp(outImg==label);

            nObjects = objectCCP.NumObjects;

            % Extract object location
            objectQueue =  struct('objID',{},'bbox',{},'assigned',{});

            for i=1:nObjects
               objectPixels = objectCCP.PixelIdxList{i};

               [y,x] = ind2sub(size(outImg),objectPixels);
               topY = min(y); topX = min(x);
               botY = max(y); botX = max(x);

               objID = objID+1;

               locationLUT(y,x)=objID;
               resultImg(y,x)=label;

               objectList(end+1).objID=objID;
               objectList(end).objClass=label;
               objectList(end).bbox=[topY,topX,botY,botX];

               objectQueue(end+1).objID=objID;
               objectQueue(end).bbox=[topY,topX,botY,botX];
               objectQueue(end).assigned=0;
    %            rectangle('Position',[topX,topY,botX-topX,botY-topY],'EdgeColor','w');
            end

            nAssigned=0;
            % Form element groups
            while nAssigned<length(objectQueue)

                % Take first non-assigned element
                for i=1:length(objectQueue)
                    if ~objectQueue(i).assigned
                        object = objectQueue(i);
                        % Assign it to a new group
                        objectQueue(i).assigned=1;
                        nAssigned = nAssigned + 1;
                        groupIDs = object.objID;
                        break;
                    end
                end

                % Go through all non-assigned elements, add aligned to the same group
                bbox = object.bbox;
                centerY = (bbox(1)+bbox(3))/2;
                for i=1:length(objectQueue)
                    if ~objectQueue(i).assigned
                        bbox2= objectQueue(i).bbox;
                        centerY2 = (bbox2(1)+bbox2(3))/2;

                        % Check whether horizontal alignment is satisfied
                        if (centerY>bbox2(1) && centerY<bbox2(3) ) || ...
                            (centerY2>bbox(1) && centerY2<bbox(3) )
                            objectQueue(i).assigned=1;
                            nAssigned = nAssigned + 1;
                            groupIDs(end+1)=objectQueue(i).objID;
                        end
                    end

                end

                objectGroupList(end+1).objClass = label;
                objectGroupList(end).groupIDs = groupIDs;

            end
        end
%         disp(objectGroupList);
        
       fig = figure(2);imagesc(locationLUT);
       set(fig,'Position',[0 200 400 400])
       
       for class=[1]
           windowList = objectList([objectList.objClass]==class);
           SymmetryVoting(windowList,sgmp);
           
       end
%         for i=1:length(objectGroupList)
%             bboxGroup = GroupBoundingBox(objectList,objectGroupList(i).groupIDs);
%             topX=bboxGroup(2);
%             topY=bboxGroup(1);
%             botX=bboxGroup(4);
%             botY=bboxGroup(3);
%             rectangle('Position',[topX,topY,botX-topX,botY-topY],'EdgeColor','w');
%         end
                
%     end
end


function bbox = GroupBoundingBox(objectList,groupIDs)
    nObjects = length(groupIDs);
    
    bbox = objectList(groupIDs(1)).bbox;
    for i=2:nObjects
        bbox2 = objectList(groupIDs(i)).bbox;
        if bbox2(1)<bbox(1)
            bbox(1)=bbox2(1);
        end
        if bbox2(2)<bbox(2)
            bbox(2)=bbox2(2);
        end
        if bbox2(3)>bbox(3)
            bbox(3)=bbox2(3);
        end
        if bbox2(4)>bbox(4)
            bbox(4)=bbox2(4);
        end
    end
    

    
end