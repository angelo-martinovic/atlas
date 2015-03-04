
function output = elementSampling(origImg,sgmp,outImg,hyperParameters)
    
    %% Setup
    draw=false;

    addpath('/esat/sadr/amartino/threeLayer/ssim/');
    addpath(genpath('/esat/sadr/amartino/threeLayer/vlfeat-0.9.14/toolbox/'));

    vl_setup;
    
    %% Initial elements
    disp('--Extracting initial elements...');
    
    PM_win = sgmp(:,:,hyperParameters.winClass);  PM_win = imfilter(PM_win, fspecial('gaussian',5,5));
    
    % Get bounding boxes using minimum bounding rectangles
    [win_boundingBoxes, win_ddw, win_ddh, poolBBwin] = getBoundingBoxesPool(hyperParameters.winClass,outImg,PM_win);

    poolBB=[];
    if ~isempty(poolBBwin)
       poolBB = poolBBwin;
    end
    
    all_boundingBoxes = win_boundingBoxes;
    
    if isfield(hyperParameters,'balcClass')
        PM_balc = sgmp(:,:,hyperParameters.balcClass); PM_balc = imfilter(PM_balc, fspecial('gaussian',5,5));
        [balc_boundingBoxes, balc_ddw,balc_ddh, poolBBbalc] = getBoundingBoxesPool(hyperParameters.balcClass, outImg, PM_balc);

        balc_ddw = round (balc_ddw);
        balc_ddh = round (balc_ddh);
    
        % Snap balconies to windows
        balc_boundingBoxes = checkBB(balc_boundingBoxes, win_boundingBoxes, win_ddw);
        poolBBbalc = checkBB(poolBBbalc, win_boundingBoxes, win_ddw);
        if ~isempty(poolBBbalc)
            poolBB = [poolBB poolBBbalc];
        end
        all_boundingBoxes = [all_boundingBoxes balc_boundingBoxes];
    end

    if isfield(hyperParameters,'doorClass')
        PM_door = sgmp(:,:,hyperParameters.doorClass);
        [door_boundingBoxes, ~, ~] = getBoundingBoxes(hyperParameters.doorClass, outImg, PM_door);
        all_boundingBoxes = [all_boundingBoxes door_boundingBoxes];
    end
    
    %% Vertical region order
    if hyperParameters.principles.verticalRegionOrder
        disp('--Principle: Vertical region order...');
        ypos = findElementOrder(outImg,sgmp, win_ddh*2);
    end

    %% Door
    if hyperParameters.principles.door
        disp('--Principle: Door...');
        door_boundingBoxes =  findDoor(ypos(4), PM_door, door_boundingBoxes, win_ddw*2, balc_ddh*2);
    end
        

    %% Symmetry
    
    mbbx1 = []; % windows
    mbbx2 = []; % balconies
        
    if hyperParameters.principles.symmetry
        disp('--Principle: Symmetry...');
        if hyperParameters.principles.verticalRegionOrder
            % Restrict the search to a part of image
            [symscore, sympos]= symmetryDetect(origImg,[ypos(2) ypos(4)]);
        else
            % Search on the entire image
            [symscore, sympos]= symmetryDetect(origImg,[1 size(outImg,1)]);
        end

        if symscore > hyperParameters.t_sym
            mbbx1 = getMirroredBBx(win_boundingBoxes, sympos, size(origImg,2));

            if isfield(hyperParameters,'balcClass')
                mbbx2 = getMirroredBBx(balc_boundingBoxes, sympos, size(origImg,2));
            end
        end
    end
   
    %% Sampling
    fprintf('--Running subsampling and optimization');
    best_score = Inf;
    best_boxes = [];
    
    all_boundingBoxes = round( all_boundingBoxes);
    [all_boundingBoxes, rest] = checkOverlap(all_boundingBoxes);
        
   for s=1:hyperParameters.num_sampling
       disp('.');
       
       %% Subsample
       disp('---Subsampling...');
       rem = zeros(1, size(all_boundingBoxes,2)) == 0;
       for bb_idx=1: size(all_boundingBoxes,2)
           thisBB = all_boundingBoxes(:,bb_idx);
           
           p = 1-hyperParameters.p_rem;
           if (rand(1) >= p)
               rem(1,bb_idx) = false;
           end
           
           %Keep doors
           if thisBB(5) ==4
              rem(1,bb_idx) = true; 
           end
           
       end

       current_boundingBoxes = all_boundingBoxes(:,rem);
       current_pool = [all_boundingBoxes(:,~rem) poolBB];
      
       current_windows = current_boundingBoxes(:,current_boundingBoxes(5,:) == hyperParameters.winClass);
       current_windows_pool = current_pool(:,current_pool(5,:) == hyperParameters.winClass);
       
       current_boxes = current_windows;
       
       
       if isfield(hyperParameters,'balcClass')
           current_balcs = current_boundingBoxes(:,current_boundingBoxes(5,:) == hyperParameters.balcClass);
           current_balcs_pool = current_pool(:,current_pool(5,:) == hyperParameters.balcClass);
           
           current_boxes = [current_boxes current_balcs]; %#ok<AGROW>
           
       end
       
       if isfield(hyperParameters,'doorClass')
           current_boxes = [current_boxes door_boundingBoxes]; %#ok<AGROW>
       end
       
      
           
       %% Propose new elements
       
       if hyperParameters.principles.similarity
           disp('---Principle: Similarity...');
           newBoxes = sampleNewBoxes(origImg, current_windows, draw,win_ddw, win_ddh, sum(all_boundingBoxes(5,:) == hyperParameters.winClass) );
           current_windows_pool = [current_windows_pool newBoxes]; %#ok<AGROW>

           current_pool = current_windows_pool;

           if isfield(hyperParameters,'balcClass')
               newBalcBoxes = sampleNewBalcBoxes(origImg, current_balcs, false,balc_ddw, balc_ddh, sum(all_boundingBoxes(5,:) == hyperParameters.balcClass) );
               current_balcs_pool = [current_balcs_pool newBalcBoxes]; %#ok<AGROW>

               current_pool = [current_pool current_balcs_pool]; %#ok<AGROW>
           end
       
       end
       
       current_pool = [current_pool mbbx1 mbbx2 rest]; %#ok<AGROW>
       
       % remove all from pool that cannot be selected
       current_pool = cleanPool(current_boxes, current_pool);
       
       if isfield(hyperParameters,'balcClass')
           current_boxes = cleanFacade(current_boxes,hyperParameters.balcClass);
       end

       %% Find the best configuration
       hyperParameters.win_ddw = win_ddw;
       hyperParameters.win_ddh = win_ddh;
       disp('---Optimizing...');
       [score, boxes] = optimizeConfiguration(current_boxes,current_pool, outImg, hyperParameters);
       
       if score < best_score
          best_boxes = boxes;
          best_score = score;
       end
         
   end
   
   %% Alignment
   disp('--Principle: Alignment...');
   if true
       opts = optimoptions(@fminunc,'Algorithm','quasi-newton','Display','off');
       
       windows = best_boxes(:,(best_boxes(5,:) == hyperParameters.winClass));
       rest1 = best_boxes(:,(best_boxes(5,:) ~= hyperParameters.winClass));
       windows = fminunc(@(x) objfun3(x,PM_win,win_ddw, win_ddh), windows, opts);
       best_boxes = [windows rest1];
       
       if isfield(hyperParameters,'balcClass')
           balcs = best_boxes(:,(best_boxes(5,:) == hyperParameters.balcClass));
           rest2 = best_boxes(:,(best_boxes(5,:) ~= hyperParameters.balcClass));
           balcs = fminunc(@(x) objfun3(x,PM_balc,balc_ddw, balc_ddh), balcs, opts);
           best_boxes = [balcs rest2];
       end
   end
   
   
   %% Output
   disp('--Creating the output label map...');
   output = zeros(size(origImg,1), size(origImg,2));

   % Background
   if hyperParameters.principles.verticalRegionOrder
       output(ypos(1):ypos(2),1:size(origImg,2)) = 6;   % sky
       output(ypos(2)+1:ypos(3),1:size(origImg,2)) = 5; % roof
       output(ypos(3)+1:ypos(4),1:size(origImg,2)) = 2; % wall
       output(ypos(4)+1:ypos(5),1:size(origImg,2)) = 7; % shop;
   else
       output = outImg;
       nonwinClasses = setdiff(1:8,hyperParameters.winClass);
       [~,nonwins] = max(sgmp(:,:,nonwinClasses),[],3);
       output(outImg==hyperParameters.winClass) = nonwins(outImg==hyperParameters.winClass);
   end
   
   % Objects
   wins = round(best_boxes(:,best_boxes(5,:) == hyperParameters.winClass));
   for i=1:size(wins,2)
       w = wins(:,i);
       output(w(2):w(4), w(1):w(3)) = hyperParameters.winClass;
   end
   
   if isfield(hyperParameters,'balcClass')
       balcs = round(best_boxes(:,best_boxes(5,:) == hyperParameters.balcClass));
       for i=1:size(balcs,2)
           w = balcs(:,i);
           output(w(2):w(4), w(1):w(3)) = hyperParameters.balcClass;
       end
   end
   
   if isfield(hyperParameters,'doorClass')
       doors = round(best_boxes(:,best_boxes(5,:) == hyperParameters.doorClass));
       for i=1:size(doors,2)
           w = doors(:,i);
           output(w(2):w(4), w(1):w(3)) = hyperParameters.doorClass;
       end
   end
   
   % Overlaid classes
   for i=1:length(hyperParameters.overrideClasses)
       output(outImg==hyperParameters.overrideClasses(i))=hyperParameters.overrideClasses(i);
   end
   
    
end

% Removes fully overlapping bounding boxes
function [outbb, outpool] = checkOverlap(all_boundingBoxes)

    remain = ones(1,size(all_boundingBoxes,2));
    for i=1:size(all_boundingBoxes,2)
        for j=i+1:size(all_boundingBoxes,2)
            a=all_boundingBoxes(:,i);
            b=all_boundingBoxes(:,j);
            ol =bb_overlap(a,b);
            aa =bb_area(a);
            ab = bb_area(b);
            if ol/min(aa,ab) ==1
               remain(i) = 0;
               remain(j) = 0;
            end
        
        end
    end
    outbb = all_boundingBoxes(:,remain==1);
    outpool = all_boundingBoxes(:,remain==0);
end

% Modifies the balcony bounding boxes to correspond to windows
function ret = checkBB(balc, win, dw)
    % For every balcony
    for i=1:size(balc,2)
       b = balc(:,i);
       
       % Check balcony size
       if (b(3) - b(1)) < dw*2
           
           % Find the windows that might be close to the balcony
           w = win(:,win(3,:) > b(1) & win(1,:) < b(3) & win(4,:) < b(4));
           dmin = Inf;
           
           % Find the window closest to the balcony
           for kk=1: size(w,2)
              d = abs(w(4,kk) -b(4));
              if d< dmin
                 dmin = d;
                 this_win = w(:,kk);
              end
           end
           % If a window is found, resize the balcony size to fit the window
           if ~isempty(w)
            balc(1,i) = this_win(1);
            balc(3,i) = this_win(3);
           end
       end
    end
    ret = balc;

end

% Extracts bounding boxes without alternatives
function [boundingBoxes, medianw, medianh, bw] = getBoundingBoxes(classidx, outImg, pm)
    mask = (outImg ==classidx);
    show = 0;
    bw =  imdilate(mask, [1 1 1; 1 0 1; 1 1 1]);
    bw =  imdilate(bw, [1 1 1; 1 0 1; 1 1 1])- mask;
    if show==1
        figure(123); axis image;
        imagesc(mask);
    end
    [conComp, n] = bwlabel(mask);
    widths = [];
    heights = [];
    boundingBoxes = zeros(6,n); np=0;
    for i=1:n

       t = (conComp ==i);
       [r,c] = find(t);
      
       x1 = min(c);
       y1 = min(r);
       x2 = max(c);
       y2 = max(r);
       widths(i) = x2-x1;
       heights(i) = y2-y1;
 
      
       np = np + 1;
       score = sum(sum(pm(y1:y2, x1:x2) )) / ((y2-y1) * (x2-x1));
       boundingBoxes(:, np) = [x1,y1, x2,y2, classidx, score];
       
    end
    medianw =round(median(widths)/2.0);
    medianh = round(median(heights)/2.0);
    boundingBoxes = boundingBoxes(:, 1:np);
end

% Extracts bounding boxes with a pool of alternatives
function [boundingBoxes, medianw, medianh, poolBB] = getBoundingBoxesPool(classidx, outImg, pm)
    mask = (outImg ==classidx);
    show = 0;
    bw =  imdilate(mask, [1 1 1; 1 0 1; 1 1 1]);
    bw =  imdilate(bw, [1 1 1; 1 0 1; 1 1 1])- mask;
    if show==1
        figure(123); axis image;
        imagesc(bw);
    end
    [conComp, n] = bwlabel(mask);
    widths = [];
    heights = [];
    boundingBoxes = zeros(6,n); np=0;
    poolBB = zeros(6,3*n);npp = 0;
    for i=1:n

       t = (conComp ==i);
       [r,c] = find(t);
      
       x1 = min(c);
       y1 = min(r);
       x2 = max(c);
       y2 = max(r);
       widths(i) = x2-x1;
       heights(i) = y2-y1;
       
       if widths(i)<=1 || heights(i)<=1
           continue;
       end

       nf = sum(sum(pm(y1:y2, x1:x2)));
       
       %search for max until mass < 80% of nf
       maxy = 1;
       maxl = -inf;
       linev = zeros(1,y2-1-y1); c=1;
       for yy = y1:y2-1
           m = sum(sum(pm(yy:y2, x1:x2)))/nf;
           if m<0.6
               break;
           end
           if yy < 3 || yy+2 > size(bw,1)
               line = sum(sum(bw(yy:yy,x1:x2)))/((x2-x1));
           else
                line = sum(sum(bw(yy-2:yy+2,x1:x2)))/((x2-x1)*5);
           end
           linev(c) = line;
           if line>maxl
               maxl = line;
               maxy = yy;
           end
           c = c+1;
       end
       mlinev = max(linev);
       m1t = find(linev ==mlinev,1);
       linev(max(1,m1t-2):min(m1t+2,size(linev,2))) = 0;
       m2t = find(linev ==max(linev),1);
       if mlinev*0.75 > linev(m2t)
          m2t = 0; 
       else
           m2t = m2t+y1;
       end
       
       y1 = maxy;
       maxy = 1;
       maxl = -inf;
       linev = zeros(1,y2-1-y1); c=1;
       for yy = y2:-1:(y1-1)

           m = sum(sum(pm(y1:yy, x1:x2)))/nf;
           if m<0.6
               break;
           end
           line = sum(sum(bw(yy-2:yy+2,x1:x2)))/((x2-x1)*5);
           linev(c) = line;
           if line>maxl
               maxl = line;
               maxy = yy;
           end
          c = c+1; 
       end
       y2=maxy;
       mlinev = max(linev);
       m1b = find(linev ==mlinev,1);
       
       linev(max(1,m1b-2):min(m1b+2,size(linev,2))) = 0;
       m2b = find(linev ==max(linev),1);
       if mlinev*0.75 > linev(m2b)
          m2b = 0;
       else
           m2b = y2 -m2b;
       end

       np = np + 1;
       score = sum(sum(pm(y1:y2, x1:x2) )) / ((y2-y1) * (x2-x1));
       boundingBoxes(:, np) = [ x1,y1, x2,y2, classidx, score];
       
       if m2t ~= 0
          npp = npp + 1;
          score = sum(sum(pm(m2t:y2, x1:x2) )) / ((y2-m2t) * (x2-x1));
          poolBB(:, npp) = [ x1,m2t, x2,y2, classidx, score];
       end
       if m2b ~=0
          npp = npp + 1;
          score = sum(sum(pm(y1:m2b, x1:x2) )) / ((m2b-y1) * (x2-x1));
          poolBB(:, npp) = [ x1,y1, x2,m2b, classidx, score];
       end
        if m2b ~=0 && m2t ~= 0
          npp = npp + 1;
          score = sum(sum(pm(m2t:m2b, x1:x2) )) / ((m2b-m2t) * (x2-x1));
          poolBB(:, npp) = [ x1,m2t, x2,m2b, classidx, score];
       end
       
    end
    poolBB = poolBB(:,1:npp);
    medianw =round(median(widths)/2.0);
    medianh = round(median(heights)/2.0);
    boundingBoxes = boundingBoxes(:, 1:np);
end


