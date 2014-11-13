function [best_model,inliers,best_error] = RansacGrid(objectList,sgmp)
    best_model=[];
    best_error = Inf;
%     best_error = 0;
    inliers=[];
        
    best_consensus_set = [];
    best_initial_set=[];
    
    imageSize = [size(sgmp,1) size(sgmp,2)];
    
    n = 3;
    k = 100;
    d = 3;
    
    if length(objectList)<n
        return;
    end
    
    data = 1:length(objectList);
    
    iterations = 0;
    while iterations<k
       
       maybe_inliers = randsample(data,n);
       [maybe_model,error,newPoints] = FitModelToMorePoints(objectList,maybe_inliers,sgmp);
       if ~isinf(error)
           consensus_set = newPoints;
%            rejected_set = [];
%            disp(maybe_inliers);
%            VisualizeSet(objectList,consensus_set,rejected_set,maybe_inliers,imageSize);
           
%            for i=1:length(data)
%                if ~ismember(data(i),maybe_inliers)
%                    if FitPointToModel(objectList(data(i)),maybe_model)
%                        consensus_set(end+1) = data(i);
%                    else
%                        rejected_set(end+1) = data(i);
%                    end
%                end
%            end
           if length(consensus_set)>d
               % Fit model to the consensus set and update the set
               this_model = maybe_model;
               this_error=error;
%                [this_model,this_error,consensus_set] = FitModelToMorePoints(objectList,consensus_set,sgmp);
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
        
       
        VisualizeGrid(objectList(best_consensus_set),best_model.anchorX,best_model.anchorY,best_model.dX,best_model.dY,imageSize);

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

function [model,error] = FitModelToThreePoints(objectList,points)
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
    
    
    % If three points are collinear, return error
    if abs(obj(1).x-obj(2).x)<=(obj(1).w+obj(2).w)/2 && abs(obj(2).x-obj(3).x)<=(obj(2).w+obj(3).w)/2 ||...
       abs(obj(1).y-obj(2).y)<=(obj(1).h+obj(2).h)/2 && abs(obj(2).y-obj(3).y)<=(obj(2).h+obj(3).h)/2
        error = 1;
        return;
    end
    
    diffsX = [abs(obj(1).x-obj(2).x),abs(obj(2).x-obj(3).x),abs(obj(1).x-obj(3).x)];
    diffsY = [abs(obj(1).y-obj(2).y),abs(obj(2).y-obj(3).y),abs(obj(1).y-obj(3).y)];
    
    % All differences between elements must be (close to) the multiplier of
    % the smallest one
    
    minDiffX = min(diffsX(diffsX>epsAlignment));
    minDiffY = min(diffsY(diffsY>epsAlignment));
    
    factorsX = diffsX./minDiffX;
    factorsY = diffsY./minDiffY;
    
    errorsX = abs(round(factorsX)-factorsX);
    errorsY = abs(round(factorsY)-factorsY);
    
    if (max(errorsX)>epsMultiplier || max(errorsY)>epsMultiplier)
        error = 1;
        return;
    end
    
    % Model (grid) can be described with a point and x,y displacements
    model = struct('anchorX',obj(1).x,'anchorY',obj(1).y,'dX',minDiffX,'dY',minDiffY);
    error = 0;

end

function [model,error,newPoints] = FitModelToMorePoints(objectList,points,sgmp)
    % Points are indices to objectList, indexing the objects fitting well
    % with the current model.
    imageSize = [size(sgmp,1) size(sgmp,2)];
    
    model = [];
    error = Inf;
    newPoints =[];
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
    
    %% First, robustly estimate a grid from selectedPoints.
    % These points must already more or less lie on a grid, otherwise they
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
    
    diffsX = diffsX(diffsX>eps);
    diffsY = diffsY(diffsY>eps);
    
    if isempty(diffsX) || isempty(diffsY)
        %Collinear points
        return;
    end
    % Suppress differences smaller than eps
    % Kernel density estimation
    [fx,xi] = ksdensity(diffsX,'width',bandwidth);
    [fy,yi] = ksdensity(diffsY,'width',bandwidth);
    
    [~,posX] = max(fx);
    [~,posY] = max(fy);
    
    dx = xi(posX);
    dy = yi(posY);
    
    if (dx<10 || dy<10)
        warning('aaa');
        return;
    end
    
    % Find the anchor by minimizing the difference between object centers
    % and nearest grid elements
    f = @(x)GridFitness(x,dx,dy,selectedPoints,imageSize);
    
    opts1= optimset('display','off');
    x = lsqnonlin(f,[dx/2,dy/2],[0,0],[dx,dy],opts1);
    anchorX = x(1);
    anchorY = x(2);
    
%     VisualizeGrid(anchorX,anchorY,dx,dy,imageSize);
    model = struct('anchorX',anchorX,'anchorY',anchorY,'dX',dx,'dY',dy);
    
    %% Refine inliers
    
    % Add points fitting to refined grid
    locationLUT = CreateLUT(x,dx,dy,selectedPoints,imageSize);
    data = 1:length(objectList);
    addMask = zeros(size(points,2),1);
    for i=1:length(data)
       if ~ismember(data(i),points)
           if FitPointToGrid(objectList(data(i)),locationLUT)
               addMask(i) = 1;
           end
       end
    end
    points = [points, data(addMask==1)];
    
    % Remove points no longer fitting
    removeMask = zeros(size(points,2),1);
    for i=1:size(points,2)
       if ~FitPointToGrid(objectList(points(i)),locationLUT)
           removeMask(i)=1;
       end
    end
    points = points(removeMask==0);
    newPoints = points;
    
    selectedPoints = objectList(points);
           
    %% Accumulating errors
    % 1. Bounding box centers not aligned with the grid
    error1 = 0;% sum(f(x).^2);
    
    % 2. Sum of std. deviations of bbox sizes
    bboxes = [selectedPoints.bbox];
    widths=bboxes(4:4:end)-bboxes(2:4:end);
    heights=bboxes(3:4:end)-bboxes(1:4:end);
    error2 = std(widths) + std(heights);
    
    
    % 3. Data term 1 - grid elements not covered by objects
    error3 = 0;% GridNonCoveredness(x,dx,dy,selectedPoints,probMap);
    
    % 4. Data term 2 - existing objects covering high-energy areas
    error4 = DataTerm(x,dx,dy,selectedPoints,sgmp);
    
    error = error1+error2+error3+error4;
    
end

function success = FitPointToGrid(point,locationLUT)

   bbox = point.bbox;
   pointMask = zeros(size(locationLUT));
   
   pointMask(bbox(1):bbox(3),bbox(2):bbox(4))=1;
   
   overlap = sum(sum(locationLUT & pointMask));
   
   objectCCP = bwconncomp(locationLUT>0);
   
   templateArea = length(objectCCP.PixelIdxList{1});
   objectArea = (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);
   
   union = templateArea+objectArea-overlap;
   
   success = (overlap/union)>0;

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

function VisualizeGrid(objects,anchorX,anchorY,dx,dy,imageSize)

        bboxes = [objects.bbox];
        botPositions=bboxes(3:4:end);
        topPositions=bboxes(1:4:end);
        leftPositions=bboxes(2:4:end);
        rightPositions=bboxes(4:4:end);
        widths=rightPositions-leftPositions;
        heights=botPositions-topPositions;

        meanW = mean(widths);
        meanH = mean(heights);
    
        
    fig=figure(222);
    set(fig,'Position',[400 1000 400 400]);
    image(zeros(imageSize));
    
    y=anchorY;
    while y<imageSize(1)
        x=anchorX;
        while x<imageSize(2)
            if ~(x<min(leftPositions) || x>max(rightPositions) || y<min(topPositions) || y>max(botPositions))
                rectangle('Position',[x-meanW/2,y-meanH/2,meanW,meanH],'EdgeColor','w');
            end
            x=x+dx;
        end
        y = y+dy;
    end

end

function f = GridFitness(x,dX,dY,objects,imageSize)
    % x is the anchor, value we are searching for.
    % dx and dy are grid spacings (determined earlier)
    % objects describe the bounding boxes
    locationLUT = CreateLUT(x,dX,dY,objects,imageSize);
    f = zeros(length(objects),1);
    
    for i=1:length(objects)
        bbox = objects(i).bbox;
        
        pointMask = zeros(size(locationLUT));
        pointMask(bbox(1):bbox(3),bbox(2):bbox(4))=1;
        
        overlap = sum(sum(locationLUT & pointMask));
   
        objectCCP = bwconncomp(locationLUT>0);

        templateArea = length(objectCCP.PixelIdxList{1});
        objectArea = (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);

        union = templateArea+objectArea-overlap;
 
        f(i) = sqrt(1-(overlap/union));
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
    
    weight = 1;
%     Egrid = -weight*( 8*(gX-2)*(gY-2)+12*(gX+gY-4)+16);
%     Egrid = numel(objects)/(gX*gY);
    Egrid = 0;
    Eproposed = sum(sum(-log(probMapLabel(locationLUT==1)))) + ...
        sum(sum(-log(probMapNotLabel(locationLUT~=1))));
    Eproposed = Eproposed / (imageSize(1)*imageSize(2));
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
    
    y=anchorY;
    while y<imageSize(1)
        x=anchorX;
        while x<imageSize(2)
            % Find if some object covers it
            if ~(x<min(leftPositions) || x>max(rightPositions) || y<min(topPositions) || y>max(botPositions))
        
                topY=round(y-meanH/2);
                botY=round(y+meanH/2);
                topX=round(x-meanW/2);
                botX=round(x+meanW/2);

                if topY<1, topY=1;end;
                if botY>imageSize(1), botY=imageSize(1);end;
                if topX<1, topX=1;end;
                if botX>imageSize(2), botX=imageSize(2);end;

                locationLUT(topY:botY,topX:botX)=1;
                
            end
            x = x+dx;
        end
        y=y+dy;
    end
%     fig=figure(444);imagesc(locationLUT);
%     set(fig,'Position',[800 1000 400 400]);
end
