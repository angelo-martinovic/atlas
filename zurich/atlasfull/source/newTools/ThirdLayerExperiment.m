for img=1:24

    %% Load the 2nd layer output
    load(['/esat/sadr/amartino/RNN/repo/source/markus_journal/markus_haussmann_eval_fold'...
        '_1_img_' num2str(img) '.mat'], 'outImg');

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
    figure(1);imagesc(outImg);
    for label = [1 3 4]
        objectCCP = bwconncomp(outImg==label);

        nObjects = objectCCP.NumObjects;
        
        % Extract object location
        locationLUT = zeros(size(outImg));
        for i=1:nObjects
           objectPixels = objectCCP.PixelIdxList{i};

           [y,x] = ind2sub(size(outImg),objectPixels);
           topY = min(y); topX = min(x);
           botY = max(y); botX = max(x);

           locationLUT(y,x)=i;
           resultImg(y,x)=label;
%            rectangle('Position',[topX,topY,botX-topX,botY-topY],'EdgeColor','w');
        end
        figure(1+label);imagesc(locationLUT);
        
        % Find object neighbors
        for i=1:nObjects
            
            [y,x] = find(locationLUT==i);
            objCenterX = (min(x)+max(x))/2;
            objCenterY = (min(y)+max(y))/2;

            % Extract column above object
            column = locationLUT(1:min(y)-1,min(x):max(x));
            % Find lowest non-zero
            [yC,xC] = find(column);
            [~,index] = max(yC);
            if ~isempty(index)
                neighIndex = column( yC(index),xC(index) );
                
                [yC,xC] = find(locationLUT==neighIndex);
                nObjCenterX = (min(xC)+max(xC))/2;
                nObjCenterY = (min(yC)+max(yC))/2;
                
                line([objCenterX nObjCenterX],[objCenterY nObjCenterY],'Color','w');
            
            end
            
            % Extract column under object
            column = locationLUT(max(y)+1:end,min(x):max(x));
            % Find highest non-zero
            [yC,xC] = find(column);
            [~,index] = min(yC);
            if ~isempty(index)
                neighIndex = column( yC(index),xC(index) );
            
                [yC,xC] = find(locationLUT==neighIndex);
                nObjCenterX = (min(xC)+max(xC))/2;
                nObjCenterY = (min(yC)+max(yC))/2;
                
                line([objCenterX nObjCenterX],[objCenterY nObjCenterY],'Color','w');
            end
            
            % Extract row left of object
            row = locationLUT(min(y):max(y),1:min(x)-1);
            % Find rightest non-zero
            [yC,xC] = find(row);
            [~,index] = max(xC);
            if ~isempty(index)
                neighIndex = row( yC(index),xC(index) );
                            
                [yC,xC] = find(locationLUT==neighIndex);
                nObjCenterX = (min(xC)+max(xC))/2;
                nObjCenterY = (min(yC)+max(yC))/2;
                
                line([objCenterX nObjCenterX],[objCenterY nObjCenterY],'Color','w');
            end
            % Extract row right of object
            row = locationLUT(min(y):max(y),max(x)+1:end);
            % Find leftest non-zero
            [yC,xC] = find(row);
            [~,index] = min(xC);
            if ~isempty(index)
                neighIndex = row( yC(index),xC(index) );
                            
                [yC,xC] = find(locationLUT==neighIndex);
                nObjCenterX = (min(xC)+max(xC))/2;
                nObjCenterY = (min(yC)+max(yC))/2;
                
                line([objCenterX nObjCenterX],[objCenterY nObjCenterY],'Color','w');
            end
        end
    end
    
    figure(6);imagesc(resultImg);

    pause;
end
