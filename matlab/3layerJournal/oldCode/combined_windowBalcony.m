
function combined_windowBalcony(namestr, savename, counter)
    %close all;
    
    %SETUP PROBLEM
    draw=false;
    addpath('/users/visics/mmathias/sw/ssim');
    addpath(genpath('/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox'));
    vl_setup;
    %END SETUP PROBLEM
    
    load(namestr);
    if draw
        figure(111) ; imagesc(outImg); axis image;
        figure(112); imagesc(origImg); axis image; hold on
    end

   %get Bounding boxes using minimum bounding rectangle
   [win_boundingBoxes, win_widths,win_heights] = getBoundingBoxes(1,outImg,draw);
   win_ddw =median(win_widths)/2.0;
   win_ddh = median(win_heights)/2.0;
   %drawRects(win_boundingBoxes, counter, outImg);
   
    

   
   % split and merge very heuristic
   win_boundingBoxes = splitMergedBB(win_boundingBoxes);
   drawRects(win_boundingBoxes, counter+1000, origImg);
   
   PM_win = sgmp(:,:,1);
   PM_win = imfilter(PM_win, fspecial('gaussian',5,5));
   %figure(334) ; imagesc(PM_win); axis image;
   %dd is the alignment distance threshold set to half the mean bb size

   
   %load BALCONIES id 3
   PM_balc = sgmp(:,:,3);
   PM_balc = imfilter(PM_balc, fspecial('gaussian',5,5));
 
   [balc_boundingBoxes, balc_widths,balc_heights, balcontourimg] = getBoundingBoxesBalc(3, outImg, PM_balc, draw);
   balc_ddw =median(balc_widths)/2.0;
   balc_ddh = median(balc_heights)/2.0;
 
   
  
   %load DOORS id 4
   [door_boundingBoxes, door_widths,door_heights, doorcontourimg] = getBoundingBoxes(4,outImg,draw);
   %door_boundingBoxes = findDoor(door_boundingBoxes, win_ddw*2, win_ddh*2);
  
   ypos = findElementOrder(outImg,sgmp, win_ddh*2);
   figure(counter+4000);
   imagesc(origImg);axis image; hold on;
   for i=1:size(ypos,2)
       line([1,size(origImg,2)], [ypos(i) ypos(i)], 'LineWidth',4,'Color',[.11 .98 .98]);
        
   end
   door = findDoor(ypos(4),sgmp(:,:,4), door_boundingBoxes, win_ddw*2, balc_ddh*2);
   figure(counter+100);imagesc(sgmp(:,:,4)); axis image
   
 %   return;
   
   %%% search for running balconies
   
   
   
   %%%detecting grid lines
%    ypositions = unique([win_boundingBoxes(2,:)-ones(1,size(win_boundingBoxes,2)) win_boundingBoxes(4,:)+ones(1,size(win_boundingBoxes,2))]);
%    ypositions = double(removePositions(win_boundingBoxes, ypositions));
%    
%    figure(1234); imagesc(origImg); axis image;
%    hold on
%    x0=1;
%    xend=size(origImg,2);
%    for k=1:size(ypositions,2)  
%        line([x0 xend],[ypositions(k) ypositions(k)],'LineWidth',4,'Color',[.11 .11 .98]);  
%    end
% 
%    opts = optimset('Display', 'iter');
%    [gridhor,fval,exitflag] = fminunc(@(ypositions) horrgridopt(win_boundingBoxes,ypositions,PM_win,win_ddw, win_ddh), ypositions, opts);
% 
%    for k=1:size(ypositions,2)  
%        line([x0 xend],[gridhor(k) gridhor(k)],'LineWidth',4,'Color',[.98 .11 .98]);  
%    end
   
   %%%%%%%%%%%%%%%%%%%%optimize windows
   %drawRects(win_boundingBoxes,554, origImg);
   win_boundingBoxes = fminunc(@(win_boundingBoxes) objfun3(win_boundingBoxes,PM_win,win_ddw, win_ddh), win_boundingBoxes);
   win_boundingBoxes = removeStupidPoints(win_boundingBoxes,PM_win,win_ddw, win_ddh);
   if draw
    drawRects(win_boundingBoxes,222, origImg);
   end
   
   %use similarity voting
   [vs, maxvs]= similarityVoting(origImg, win_boundingBoxes', draw);
   newmax = findnewMaxima(vs,win_boundingBoxes,win_widths,win_heights,maxvs);
   %evaluate new maxima
   score = zeros(1,size(newmax,2));
   refscore = objfun3(win_boundingBoxes,PM_win,win_ddw, win_ddh);
   for i=1:size(newmax,2)
       winbbtmp =  [win_boundingBoxes newmax(:,i)];
       % winbbtmp = fminunc(@(winbbtmp) objfun3(winbbtmp,PM_win,win_ddw, win_ddh), winbbtmp);
       score(i) =  alignmentScore(win_boundingBoxes, newmax(:,i),3,3 )%    objfun3(winbbtmp,PM_win,win_ddw, win_ddh)
       %drawRects(winbbtmp, 988, origImg);
       
       
       
   end
   
   
   
   win_boundingBoxes = [win_boundingBoxes  newmax(:,(score==1))];
  
   %drawRects(win_boundingBoxes,554, origImg); 

   win_boundingBoxes = fminunc(@(win_boundingBoxes) objfun3(win_boundingBoxes,PM_win,win_ddw, win_ddh), win_boundingBoxes);
   
   win_boundingBoxes = removeStupidPoints(win_boundingBoxes,PM_win, win_ddw, win_ddh);
   win_boundingBoxes = fminunc(@(win_boundingBoxes) objfun3(win_boundingBoxes,PM_win,win_ddw, win_ddh), win_boundingBoxes);
   
   if draw
   drawRects(win_boundingBoxes, 557, origImg);
   end
   
   
   %%%%%%%%%%%%%%%%%%%optimize balconies
   balc_boundingBoxes = updateBBBasedOnPM(balc_boundingBoxes, balcontourimg,balc_ddw,balc_ddh);
   
   balc_boundingBoxes = fminunc(@(balc_boundingBoxes) objfunBalcony(balc_boundingBoxes,PM_balc,balc_ddw, balc_ddh), balc_boundingBoxes);
   
   %drawRects(balc_boundingBoxes, 666, origImg);
   %[vs, maxvs]= similarityVoting(origImg, balc_boundingBoxes');

   
   
   
   %%% symmetry detect
    %ypos = findElementOrder(outImg,sgmp,2*win_ddh);
   
   [symscore, sympos]= symmetryDetect(origImg, win_boundingBoxes',[ypos(2) ypos(4)]); 
   if symscore > 0.5
   
    tmp = updateMapsbySymmetryAndBB(win_boundingBoxes, sgmp,sympos, 1,win_ddw, win_ddh,1);
    %if size(win_boundingBoxes,2)/ size(tmp,2) < 0.7
    %    disp('less than 70% overlap of existing bounding boxes');
    %else
        win_boundingBoxes = tmp;
        balc_boundingBoxes = updateMapsbySymmetryAndBB(balc_boundingBoxes, sgmp,sympos, 3,balc_ddw, balc_ddh,0);     
    %end
    
    %optimize (again)
    win_boundingBoxes = fminunc(@(p) objfun3(win_boundingBoxes,PM_win,win_ddw, win_ddh), win_boundingBoxes);
    balc_boundingBoxes = fminunc(@(balc_boundingBoxes) objfunBalcony(balc_boundingBoxes,PM_balc,balc_ddw, balc_ddh), balc_boundingBoxes);
   
   
   end
   
   %----------remove single windows
   
   
    win_boundingBoxes = removeStandAloneBoundingBoxes(win_boundingBoxes,ypos(3), ypos(4));
   
   
   
   %----------end remove single windows
   
   %----------add running balconies
   [b2, b5, maxEnergy] = runningBalc(win_boundingBoxes, balc_boundingBoxes, PM_balc, ypos);
     if maxEnergy(1) > 0.13
        balc_boundingBoxes= addRunningBalc(balc_boundingBoxes,[1,b5(1), size(PM_balc,2), b5(2)]');
     end
     if maxEnergy(2) > 0.13
         balc_boundingBoxes= addRunningBalc(balc_boundingBoxes,[1,b2(1), size(PM_balc,2), b2(2)]');
     end
     
   
   if draw
   drawRects(balc_boundingBoxes, 558, origImg);
   end
   
   balc_boundingBoxes = addBalconiesOrWindows(win_boundingBoxes, balc_boundingBoxes);
 
   
   
   
   %%%%%%%%%%%%%%%%%joint but only balcony
   if draw
    drawRects(win_boundingBoxes, 560, origImg);
    drawRects(balc_boundingBoxes, 561, origImg);
   end  
   
   t1 = ones(size(win_boundingBoxes,2),1);
   t2 = 3*ones(size(balc_boundingBoxes,2),1);
   classidx = [t1; t2];
   %drawRects(balc_boundingBoxes, 888, origImg);o
   balc_boundingBoxes = extendBalcBB(win_boundingBoxes, balc_boundingBoxes, balc_ddh);
   balc_boundingBoxes = fminunc(@(balc_boundingBoxes) objfunJoint22(win_boundingBoxes, balc_boundingBoxes, classidx, PM_win, PM_balc, win_ddw, win_ddh, win_ddw, balc_ddh), balc_boundingBoxes);
   % balc_boundingBoxes = removeStandAloneBoundingBoxes(balc_boundingBoxes);

   
   if draw
    drawRects(win_boundingBoxes, 560, origImg);
    drawRects(balc_boundingBoxes, 561, origImg);
   end  
   
   save([savename '.ws']);
   
   
    %update probability maps
    win_boundingBoxes =  setBBtoImage(win_boundingBoxes, size(origImg,2), size(origImg,1));
    balc_boundingBoxes =  setBBtoImage(balc_boundingBoxes, size(origImg,2), size(origImg,1));
    sgmp(:,:,1) = updateProbabilityMap(sgmp(:,:,1), win_boundingBoxes,9);
    sgmp(:,:,3) = updateProbabilityMap(sgmp(:,:,3), balc_boundingBoxes,10);
     sgmp(:,:,4) = updateProbabilityMap(sgmp(:,:,4),  door,15);
   %use facade splitting
    
    w = size(outImg,2);
    facadebb = zeros(4,4);
    facadebb(1,1) = 1;
    facadebb(3,1) = w;
    facadebb(2,1) = ypos(1);
    facadebb(4,1) = ypos(2);
    
    facadebb(1,2) = 1;
    facadebb(3,2) = w;
    facadebb(2,2) = ypos(2);
    facadebb(4,2) = ypos(3);
    
    facadebb(1,3) = 1;
    facadebb(3,3) = w;
    facadebb(2,3) = ypos(3);
    facadebb(4,3) = ypos(4);
    
    facadebb(1,4) = 1;
    facadebb(3,4) = w;
    facadebb(2,4) = ypos(4);
    facadebb(4,4) = ypos(5);
    
    
    
    
    
    
    
    sgmp(:,:,6) = updateProbabilityMap(sgmp(:,:,6),facadebb(:,1),12);
    sgmp(:,:,5) = updateProbabilityMap(sgmp(:,:,5),facadebb(:,2) ,5);
    sgmp(:,:,2) = updateProbabilityMap(sgmp(:,:,2),facadebb(:,3) ,2);
    sgmp(:,:,7) = updateProbabilityMap(sgmp(:,:,7),facadebb(:,4) ,11);
    tmp = max(sgmp,[],3);
    figure(counter+4000);imagesc(tmp); axis image;
    
    save(savename,'sgmp');
    drawRects(balc_boundingBoxes, counter+3000, origImg);
    drawRects(win_boundingBoxes, counter+2000, origImg);
    %waitforbuttonpress
   % addBalconies
    a=3
    %figure; imagesc(sgmp(:,:,1));
    
   
   
%    %%%%%%%%%%%%%%%%%%%joint optimization
%    boundingBoxes = [win_boundingBoxes balc_boundingBoxes];
%    t1 = ones(size(win_bouhndingBoxes,2),1);
%    t2 = 3*ones(size(balc_boundingBoxes,2),1);
%    classidx = [t1; t2];
%    drawRects(boundingBoxes, 888, origImg);
%    all_boundingBoxes = fminunc(@(boundingBoxes) objfunJoint(boundingBoxes, classidx, PM_win, PM_balc, win_ddw, win_ddh, balc_ddw, balc_ddh), boundingBoxes);
%    p = all_boundingBoxes(:,classidx==1);
%    
%    drawRects(all_boundingBoxes, 777,origImg);
   
    
end

function map = updateProbabilityMap(map, bb,val)
    map= zeros(size(map));
    for i=1:size(bb,2)
       map(round(bb(2,i)):round(bb(4,i)), round(bb(1,i)):round(bb(3,i)), :) = val;%map(round(bb(2,i)):round(bb(4,i)), round(bb(1,i)):round(bb(3,i)), :)+1;
    end


end

function drawRects(p2,fignum, image)
figure(fignum); imagesc(image); axis image;
   hold on

for k=1:size(p2,2)
       
       x = round(p2(1,k));
       y = round(p2(2,k));
       w = round(p2(3,k)-p2(1,k));
       h = round(p2(4,k)-p2(2,k));
       X =[x, x+w, x+w,x+w,x+w,x, x,x];
       Y =[y, y,y, y+h, y+h,y+h, y+h, y];
       line(X,Y,'LineWidth',4,'Color',[.11 .98 .98]);  
end

end


function [boundingBoxes, widths, heights, bw] = getBoundingBoxes(classidx, outImg, show)
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
    boundingBoxes = zeros(4,n); np=0;
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
      
       boundingBoxes(:, np) = [ x1,y1, x2,y2];
       
    end
    
    boundingBoxes = boundingBoxes(:, 1:np);
end

function [boundingBoxes, widths, heights, bw] = getBoundingBoxesBalc(classidx, outImg, pm, show)
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
    boundingBoxes = zeros(4,n); np=0;
    for i=1:n

       t = (conComp ==i);
       [r,c] = find(t);
      
       x1 = min(c);
       y1 = min(r);
       x2 = max(c);
       y2 = max(r);
       widths(i) = x2-x1;
       heights(i) = y2-y1;

       nf = sum(sum(pm(y1:y2, x1:x2)));
       
       %search for max until mass < 80% of nf
       maxy = 0;
       maxl = -inf;
       for yy = y1:y2-1
           m = sum(sum(pm(yy:y2, x1:x2)))/nf;
           if m<0.7
               break;
           end
           line = sum(bw(yy,:))/(x2-x1);
           if line>maxl
               maxl = line;
               maxy = yy;
           end
           
       end
       y1 = maxy;
       maxy = 0;
       maxl = -inf;
       for yy = y2:-1:(y1-1)

           m = sum(sum(pm(y1:yy, x1:x2)))/nf;
           if m<0.7
               break;
           end
           line = sum(bw(yy,:))/(x2-x1);
           if line>maxl
               maxl = line;
               maxy = yy;
           end
           
       end
       y2=maxy;
       
       
%         nf = sum(sum(pm(y1:y2, x1:x2)));
%           %search for max until mass < 80% of nf
%        maxx = 0;
%        maxl = -inf;
%        for xx = x1:x2-1
%            m = sum(sum(pm(y1:y2, xx:x2)))/nf;
%            if m<0.7
%                break;
%            end
%            line = sum(bw(:,xx))/(y2-y1);
%            if line>maxl
%                maxl = line;
%                maxx = xx;
%            end
%            
%        end
%        x1 = maxx;
%        maxx = 0;
%        maxl = -inf;
%        for xx = x2:-1:(x1-1)
% 
%            m = sum(sum(pm(y1:y2, x1:xx)))/nf;
%            if m<0.7
%                break;
%            end
%            line = sum(bw(:,xx))/(y2-y1);
%            if line>maxl
%                maxl = line;
%                maxx = xx;
%            end
%            
%        end
%        x2=maxx;
%        
%        
%        
%        
%        
%        
       
       
       
       
      
       np = np + 1;
      
       boundingBoxes(:, np) = [ x1,y1, x2,y2];
       
    end
    
    boundingBoxes = boundingBoxes(:, 1:np);
end


