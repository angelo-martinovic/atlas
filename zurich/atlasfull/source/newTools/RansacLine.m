function [best_model,inliers] = RansacLine(objectList,sgmp)
    inliers = [];
    imageSize = [size(sgmp,1) size(sgmp,2)];
    
    n = 2;
    k = 100;
    t = 0.1;
    d = 2;
    
    if length(objectList)<2
        best_model=[];
        inliers=[];
        return;
    end
    
    data = 1:length(objectList);
    
    iterations = 0;
    best_model = [];
    best_consensus_set = [];
    best_initial_set=[];
    best_error = Inf;
    
  
    while iterations<k
       
       maybe_inliers = randsample(data,n);
       [maybe_model,error] = FitModelToTwoPoints(objectList,maybe_inliers);
       if ~error
           consensus_set = maybe_inliers;
           rejected_set = [];
%            disp(maybe_inliers);
%            VisualizeSet(objectList,consensus_set,rejected_set,maybe_inliers,imageSize);
           
           for i=1:length(data)
               if ~ismember(data(i),maybe_inliers)
                   if FitPointToModel(objectList(data(i)),maybe_model)
                       consensus_set(end+1) = data(i);
                   else
                       rejected_set(end+1) = data(i);
                   end
               end
           end
           if length(consensus_set)>d
               % Fit model to the consensus set and update the set
               [this_model,this_error,consensus_set] = FitModelToMorePoints(objectList,consensus_set,sgmp);
               % Remember best model
               if this_error<best_error
                   best_model = this_model;
                   best_consensus_set = consensus_set;
                   best_initial_set = maybe_inliers;
                   best_error = this_error;
               end 
           end
  
           
       end
       iterations = iterations+1;
       if mod(iterations,k/10)==0
            fprintf('%d', iterations);
       end
    end
    
    if ~isempty(best_model)
        VisualizeSet(objectList,best_consensus_set,[],best_initial_set,imageSize);
        VisualizeLine(best_model.anchorX,best_model.anchorY,best_model.dX,best_model.dY,imageSize);
        
%         locationLUT = CreateLUT([best_model.anchorX,best_model.anchorY],best_model.dX,best_model.dY,objectList(best_consensus_set),imageSize);
%         
%        
%         objectMask = zeros(size(locationLUT));
%         for i=1:length(objectList)
%             bbox = objectList(i).bbox;
%             objectMask(bbox(1):bbox(3),bbox(2):bbox(4))=i;
%         end
%         fig = figure(2);imagesc(objectMask);
%         set(fig,'Position',[0 1000 400 400])
%         
%         inliers = unique(objectMask(locationLUT==1));% best_consensus_set;
%         inliers = inliers(inliers>0);
          inliers = best_consensus_set;
    
    end
end

function [model,error] = FitModelToTwoPoints(objectList,points)
    model = [];
    epsAlignment = 5;   % Pixels
    epsMultiplier = 0.1;
    
    obj = struct('x',{},'y',{});
    for i=1:length(points)
        
        bbox = objectList(points(i)).bbox;
        obj(end+1).y=(bbox(1)+bbox(3))/2;
        obj(end).x=(bbox(2)+bbox(4))/2;
        
        obj(end).w=bbox(4)-bbox(2);
        obj(end).h=bbox(3)-bbox(1);
    end
    
    
    % If two points are not collinear, return error
    if ~(abs(obj(1).x-obj(2).x)<=(obj(1).w+obj(2).w)/2 || ...
         abs(obj(1).y-obj(2).y)<=(obj(1).h+obj(2).h)/2)
         error = 1;
         return;
    end
    
    diffX = abs(obj(1).x-obj(2).x);
    diffY = abs(obj(1).y-obj(2).y);
    
    if (diffX<diffY)
        diffX = 0;
        % Model (line) can be described with a point and x or y displacement
        model = struct('anchorX',obj(1).x,'anchorY',obj(1).y,'dX',diffX,'dY',diffY);
    else
        diffY = 0;
        model = struct('anchorX',obj(1).x,'anchorY',obj(1).y,'dX',diffX,'dY',diffY);
    end
    error = 0;

end

function [model,error,newPoints] = FitModelToMorePoints(objectList,points,sgmp)
    % Points are indices to objectList, indexing the objects fitting well
    % with the current model.
    imageSize = [size(sgmp,1) size(sgmp,2)];
    
    model = [];
    newPoints = [];
    error = Inf;
    % The model is estimated as a grid with an anchor and offsets in x and
    % y directions dx and dy.
    
    eps = 10; % pixels
    % Parameters of Kernel Density Estimation
    bandwidth = 5;
    
    % Error will increase for the following:
    % 1. Every bounding box center not aligned with the grid
    % 2. Every bounding box size (x and y) deviating from median
    % 3. Every grid element not covered by an object
    % 4. Mismatch with the data term (sum of data energies for every
    % bounding box)
    
    selectedPoints = objectList(points);
    
    %% First, robustly estimate a line from selectedPoints.
    % These points must already more or less lie on a line, otherwise they
    % wouldn't have been selected. 
    
    % Idea: make a histogram of differences of object center positions
    diffsX = []; diffsY= [];
    for i1=1:length(selectedPoints)-1
        for i2=i1+1:length(selectedPoints)
            bbox1 = selectedPoints(i1).bbox;
            bbox2 = selectedPoints(i2).bbox;
            cent1 = struct('x',(bbox1(2)+bbox1(4))/2,'y',(bbox1(1)+bbox1(3))/2);
            cent2 = struct('x',(bbox2(2)+bbox2(4))/2,'y',(bbox2(1)+bbox2(3))/2);
            diffsX(end+1) = abs(cent1.x-cent2.x);
            diffsY(end+1) = abs(cent1.y-cent2.y);
        end
    end
    
    % Suppress differences smaller than eps
    % Kernel density estimation
%     diffsX = diffsX(diffsX>eps);
%     diffsY = diffsY(diffsY>eps);
    
    
    if ~isempty(diffsX)
        [fx,xi] = ksdensity(diffsX,'width',bandwidth);
        [~,posX] = max(fx);
        dx = xi(posX);
        
        if (dx<eps)
            dx=0;%error('X problem');
        end
    else
        dx = 0;
    end
    
    if ~isempty(diffsY)
        [fy,yi] = ksdensity(diffsY,'width',bandwidth);
        [~,posY] = max(fy);
        dy = yi(posY);
        
        if (dy<eps)
            dy=0;%error('Y problem');
        end
    else
        dy = 0;
    end
    
    if (dx>0 && dy>0)
%         warning('Not a line.');
        return;
    end


    % Find the anchor by minimizing the difference between object centers
    % and nearest grid elements
    bbox1 = selectedPoints(i1).bbox;
    cent1 = struct('x',(bbox1(2)+bbox1(4))/2,'y',(bbox1(1)+bbox1(3))/2);
    
    origPoint = [dx/2,dy/2];
    f = @(x)LineFitness(x,dx,dy,selectedPoints,origPoint);
    
    opts1= optimset('display','off');
    if (dx==0)
        x = lsqnonlin(f,[dy/2],[0],[dy],opts1);
        anchorX = cent1.x;
        anchorY = x;
    elseif (dy==0)
        x = lsqnonlin(f,[dx/2],[0],[dx],opts1);
        anchorX = x;
        anchorY = cent1.y;
    else
        x = lsqnonlin(f,[dx/2,dy/2],[0,0],[dx,dy],opts1);
        anchorX = x(1);
        anchorY = x(2);
    end
            
     
    x= [anchorX, anchorY];
    
    
    VisualizeLine(anchorX,anchorY,dx,dy,imageSize);
    model = struct('anchorX',anchorX,'anchorY',anchorY,'dX',dx,'dY',dy);
    
    %% Refine inliers
    
    % Add points fitting to refined grid
    locationLUT = CreateLUT(x,dx,dy,selectedPoints,imageSize);
    data = 1:length(objectList);
    addMask = zeros(size(points,2),1);
    for i=1:length(data)
       if ~ismember(data(i),points)
           if FitPointToLine(objectList(data(i)),locationLUT)
               addMask(i) = 1;
           end
       end
    end
    points = [points, data(addMask==1)];
    
    % Remove points no longer fitting
    removeMask = zeros(size(points,2),1);
    for i=1:size(points,2)
       if ~FitPointToLine(objectList(points(i)),locationLUT)
           removeMask(i)=1;
       end
    end
    points = points(removeMask==0);
    newPoints = points;
    
    selectedPoints = objectList(points);
           
    %% Accumulating errors
    % 1. Bounding box centers not aligned with the grid
    error1 = 0;%sum(f(x).^2);
    
    % 2. Sum of std. deviations of bbox sizes
%     bboxes = [selectedPoints.bbox];
%     widths=bboxes(4:4:end)-bboxes(2:4:end);
%     heights=bboxes(3:4:end)-bboxes(1:4:end);
    error2 = 0;%std(widths) + std(heights);
    
    
    % 3. Data term 1 - grid elements not covered by objects
    error3 = 0;% GridNonCoveredness(x,dx,dy,selectedPoints,probMap);
    
    % 4. Data term 2 - existing objects covering high-energy areas
    error4 = DataTerm(x,dx,dy,selectedPoints,sgmp);
    
    error = error1+error2+error3+error4;
    
end

function success = FitPointToModel(point,model)
   epsAlignment = 5;   % Pixels
   
   bbox = point.bbox;
   obj = struct('x',(bbox(2)+bbox(4))/2,'y',(bbox(1)+bbox(3))/2);

   gridAnchorX = model.anchorX;
   gridAnchorY = model.anchorY;
   dX = model.dX;
   dY = model.dY;
   
   diffX = obj.x-gridAnchorX;
   diffY = obj.y-gridAnchorY;
   
   if dX>0
       factorX = round(diffX./dX);
   else
       factorX = 0;
   end
   
   if dY>0
       factorY = round(diffY./dY);
   else
       factorY = 0;
   end
   
   closestPointX = gridAnchorX+factorX*dX;
   closestPointY = gridAnchorY+factorY*dY;
   
   if closestPointX+epsAlignment>bbox(2) && closestPointX-epsAlignment<bbox(4) && ...
       closestPointY+epsAlignment>bbox(1) && closestPointY-epsAlignment<bbox(3)
         success = 1;
   else
         success = 0;
   end
%    errorX = abs(closestPointX-obj.x);
%    errorY = abs(closestPointY-obj.y);
%     
%    if (max(errorX)>epsAlignment || max(errorY)>epsAlignment)
%        success = 0;
%    else
%        success = 1;
%    end
end

function success = FitPointToLine(point,locationLUT)

   bbox = point.bbox;
   pointMask = zeros(size(locationLUT));
   
   pointMask(bbox(1):bbox(3),bbox(2):bbox(4))=1;
   
   overlap = sum(sum(locationLUT & pointMask));
   
   objectCCP = bwconncomp(locationLUT>0);
   
   templateArea = length(objectCCP.PixelIdxList{1});
   objectArea = (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);
   
   union = templateArea+objectArea-overlap;
   
   success = (overlap/union)>0.5;
  
end

function VisualizeSet(objectList,IDs,rejectedObjects,originalObjects,imageSize)
    fig=figure(111);
    set(fig,'Position',[1200 1000 400 400]);
    image(zeros(imageSize));
    for i=1:length(IDs)
        if ismember(IDs(i),originalObjects)
            color='r';
        else
            color='b';
        end
       box = objectList(IDs(i)).bbox;
       rectangle('Position',[box(2),box(1),box(4)-box(2),box(3)-box(1)],'EdgeColor',color);
    end
    for i=1:length(rejectedObjects)
        box = objectList(rejectedObjects(i)).bbox;
        rectangle('Position',[box(2),box(1),box(4)-box(2),box(3)-box(1)],'EdgeColor','w');
    end
    
end

function VisualizeLine(anchorX,anchorY,dx,dy,imageSize)
    fig=figure(222);
    set(fig,'Position',[400 1000 400 400]);
    image(zeros(imageSize));
    
    y=anchorY;
    while y<imageSize(1)
        x=anchorX;
        while x<imageSize(2)
            if dx>0
                if dy>0
                    rectangle('Position',[x-2,y-2,4,4],'EdgeColor','w');
                else
                    rectangle('Position',[x-2,1,4,imageSize(1)],'EdgeColor','w');
                end
                x=x+dx;
            else
                rectangle('Position',[1,y-2,imageSize(2),4],'EdgeColor','w');
                break;
            end
        end
        if dy>0
            y = y+dy;
        else
            break;
        end
    end

end

function f = LineFitness(x,dX,dY,objects,origPoint)
    % x is the anchor, value we are searching for.
    % dx and dy are grid spacings (determined earlier)
    % objects describe the bounding boxes
    if (dX==0)
        gridAnchorX = origPoint(1);    
        gridAnchorY = x;
    elseif (dY==0)
        gridAnchorX = x;    
        gridAnchorY = origPoint(2);
    else
        gridAnchorX = x(1);    
        gridAnchorY = x(2);
    end
    

    % Output f is the vector of euclidean distances between objects and
    % nearest grid elements.
    f = zeros(length(objects),1);
    for i=1:length(objects)
        bbox = objects(i).bbox;
        obj = struct('x',(bbox(2)+bbox(4))/2,'y',(bbox(1)+bbox(3))/2);
        
        
        diffX = obj.x-gridAnchorX;
        diffY = obj.y-gridAnchorY;

        if dX>0
            factorX = round(diffX./dX);
        else
            factorX = 0;
        end
 
        if dY>0
            factorY = round(diffY./dY);
        else
            factorY = 0;
        end
 
        closestPointX = gridAnchorX+factorX*dX;
        closestPointY = gridAnchorY+factorY*dY;
        
        f(i) = sqrt((obj.x-closestPointX)^2+(obj.y-closestPointY)^2);
    end
end

function E = DataTerm(x,dx,dy,objects,probMap)

    if isempty(objects)
        E=Inf;
        return;
    end
    
    imageSize = [size(probMap,1) size(probMap,2)];
    
    probMap(probMap==1)=0.9999;
    probMapLabel = probMap(:,:,1);
    probMapNotLabel = 1-probMapLabel;
    
%     locationLUT = zeros(size(probMap,1),size(probMap,2));
%     for i=1:length(objects)
%          bbox = objects(i).bbox;
%          locationLUT(bbox(1):bbox(3),bbox(2):bbox(4))=1;
%     end
%     
%     Eorig = sum(sum(-log(probMapLabel(locationLUT==1)))) + ...
%         sum(sum(-log(probMapNotLabel(locationLUT~=1))));
    
%     figure(333);imagesc(locationLUT);
    locationLUT = CreateLUT(x,dx,dy,objects,imageSize);
    
    % How many columns in the grid
    hor = sum(locationLUT,1);
    hor = hor/max(hor);
    gX = sum(conv(hor,[-1 1])==1);
    
    % How many rows in the grid
    ver = sum(locationLUT,2);
    ver = ver/max(ver);
    gY = sum(conv(ver,[-1 1])==1);
    
    weight = 1000;
    Egrid = -weight*( 8*(gX-2)*(gY-2)+12*(gX+gY-4)+16);
    
    Eproposed = sum(sum(-log(probMapLabel(locationLUT==1)))) + ...
        sum(sum(-log(probMapNotLabel(locationLUT~=1))));
    
    E = Eproposed+Egrid;%-Eorig;
    
end

function locationLUT = CreateLUT(x,dx,dy,objects,imageSize)
    anchorX = x(1);    
    anchorY = x(2);
    
    locationLUT = zeros(imageSize(1),imageSize(2));
    
    bboxes = [objects.bbox];
    botPositions=bboxes(3:4:end);
    topPositions=bboxes(1:4:end);
    leftPositions=bboxes(2:4:end);
    rightPositions=bboxes(4:4:end);
    widths=rightPositions-leftPositions;
    heights=botPositions-topPositions;

    meanW = mean(widths);
    meanH = mean(heights);
    
    minX = Inf; minY = Inf;
    maxX = -Inf; maxY = -Inf;
    y=anchorY;
    while y<imageSize(1)
        x=anchorX;
        while x<imageSize(2)
            % Find if some object covers it
%             if ~(x<min(leftPositions) || x>max(rightPositions) || y<min(topPositions) || y>max(botPositions))
                
                topY=round(y-meanH/2);
                botY=round(y+meanH/2);
                topX=round(x-meanW/2);
                botX=round(x+meanW/2);

                if topY<1, topY=1;end;
                if botY>imageSize(1), botY=imageSize(1);end;
                if topX<1, topX=1;end;
                if botX>imageSize(2), botX=imageSize(2);end;

                locationLUT(topY:botY,topX:botX)=1;
                
%             end
            if dx>0
                x=x+dx;
            else
                break;
            end
           
        end
        if dy>0
                y=y+dy;
        else
            break;
        end
    end
%     fig=figure(444);imagesc(locationLUT);
%     set(fig,'Position',[800 1000 400 400]);
end
