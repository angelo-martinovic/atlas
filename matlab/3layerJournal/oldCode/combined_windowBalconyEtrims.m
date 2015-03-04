
function combined_windowBalconyEtrims(namestr, savename, counter, fold)
    %close all;
    draw=false;
    addpath(genpath('/users/visics/mmathias/sw/ssim'));
    addpath(genpath('/users/visics/mmathias/sw/vlfeat-0.9.14/toolbox'));
    vl_setup;
    load(namestr);
    %%%%%%%%%Hack corrupt image
    if (fold==3 && counter == 9)
      outImg = oldImg;  
    end
    if draw
    figure(11100+counter) ; imagesc(outImg); axis image;
    figure(112); imagesc(origImg); axis image; hold on
    end
    [height, width] = size(outImg);
    PM_win = sgmp(:,:,8);
   %outImg = oldImg;
   [win_boundingBoxes, win_widths,win_heights] = getBoundingBoxes(8,outImg,draw);
  % tmp = detectionMap(:,:,8);
  % tmp = tmp >0.126;
  % [win_boundingBoxes2, win_widths2,win_heights2] = getBoundingBoxes(1,tmp,draw);
  % win_boundingBoxes = [win_boundingBoxes win_boundingBoxes2];
   %win_boundingBoxes =  win_boundingBoxes(:,(abs(win_boundingBoxes(3,:) - win_boundingBoxes(1,:))<width/3));
   % win_boundingBoxes =  win_boundingBoxes(:,(abs(win_boundingBoxes(4,:) - win_boundingBoxes(2,:))<height/3));
    
   
   %%remove very small bb
   dell = abs(win_boundingBoxes(3,:) - win_boundingBoxes(1,:)) < 20 | abs(win_boundingBoxes(4,:) - win_boundingBoxes(2,:)) < 20;
   win_boundingBoxes(:,dell) = [];
  
  
   %tmp = outImg(a);
  
   for i = 1:7
    tmp = zeros(height, width);
    a = outImg ==i;
    tmp(a) = i;
    sgmp(:,:,i) = tmp;
    
   end
   
   sgmptmp = sgmp;
   sgmptmp(:,:,8) = zeros(height, width);
   
   
   
   ks =7;
   win_boundingBoxes = splitMergedBB(win_boundingBoxes);
   PM_win = imfilter(PM_win, fspecial('gaussian',ks,ks));
   win_ddw =median(win_widths)/2.0;
   win_ddh = median(win_heights)/2.0;
   
%    if draw
%     drawRects(win_boundingBoxes,222, origImg);
%    end
%    
   %return;
   %%%%%%%%%%%%%%%%%%%%optimize windows
   %drawRects(win_boundingBoxes,554, origImg);
   win_boundingBoxes = fminunc(@(win_boundingBoxes) objfun3Etrims(win_boundingBoxes,PM_win,win_ddw, win_ddh), win_boundingBoxes);
   %win_boundingBoxes = removeStupidPoints(win_boundingBoxes,PM_win,win_ddw, win_ddh);
   %win_boundingBoxes = removeStandAloneBoundingBoxes(win_boundingBoxes,0,0);
   if draw
    drawRects(win_boundingBoxes,222, origImg);
   end
   
   %use similarity voting
   [vs, maxvs]= similarityVoting(origImg, win_boundingBoxes', draw);
   newmax = findnewMaxima(vs,win_boundingBoxes,win_widths,win_heights,maxvs);
   %evaluate new maxima
   score = zeros(1,size(newmax,2));
   refscore = objfun3Etrims(win_boundingBoxes,PM_win,win_ddw, win_ddh);
   for i=1:size(newmax,2)
       winbbtmp =  [win_boundingBoxes newmax(:,i)];
       score(i) =  alignmentScore(win_boundingBoxes, newmax(:,i),2,2 );
   end
   
   
   
   win_boundingBoxes = [win_boundingBoxes  newmax(:,(score==1))];
  

   %win_boundingBoxes = removeOverlapping(win_boundingBoxes, PM_win);
   win_boundingBoxes = fminunc(@(win_boundingBoxes) objfun3Etrims(win_boundingBoxes,PM_win,win_ddw, win_ddh), win_boundingBoxes);
   
%    win_boundingBoxes = removeStupidPoints(win_boundingBoxes,PM_win, win_ddw, win_ddh);
%    win_boundingBoxes = fminunc(@(win_boundingBoxes) objfun3Etrims(win_boundingBoxes,PM_win,win_ddw, win_ddh), win_boundingBoxes);
%    
   if draw
   drawRects(win_boundingBoxes, 557, origImg);
   end
   
  
   
   % symmetry detect
   % ypos = findElementOrder(outImg,sgmp,2*win_ddh);
%    
%    [symscore, sympos]= symmetryDetect(origImg, win_boundingBoxes',[0 0]); 
%    if symscore > 0.5
%    
%     tmp = updateMapsbySymmetryAndBB(win_boundingBoxes, sgmp,sympos, 1,win_ddw, win_ddh,1);
%    
%         win_boundingBoxes = tmp;
%    
%     %optimize (again)
%     win_boundingBoxes = fminunc(@(p) objfun3Etrims(win_boundingBoxes,PM_win,win_ddw, win_ddh), win_boundingBoxes);
%  
%    end
   
   %----------remove single windows
   
   
    %win_boundingBoxes = removeStandAloneBoundingBoxes(win_boundingBoxes,0,0);
   
   
   
   %----------end remove single windows
   
 
   save([savename '.ws']);
   
   
    %update probability maps
    win_boundingBoxes =  setBBtoImage(win_boundingBoxes, size(origImg,2), size(origImg,1));
%    balc_boundingBoxes =  setBBtoImage(balc_boundingBoxes, size(origImg,2), size(origImg,1));
    sgmp(:,:,8) = updateProbabilityMap(sgmp(:,:,8), win_boundingBoxes,8);
   
    wall = sgmp(:,:,1);
    pp = tmp ==0;
    wall(pp) = 1;
    sgmp(:,:,1) = wall;
    
    tmp = max(sgmp,[],3);
  
    
    
   

    figure(counter+4000);imagesc(tmp); axis image; 
    save(savename,'sgmp');
 
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
    n1 = 1;
    n2 = 3;
    n2=2;
    bw = mask;
    for i=1:n1
        bw =  imdilate(bw, [1 1 1; 1 0 1; 1 1 1]);
    end
    
    for i=1:n1
        bw =  imerode(bw, [1 1 1; 1 0 1; 1 1 1]);
    end

    for i=1:n2
        bw =  imerode(bw, [1 1 1; 1 0 1; 1 1 1]);
    end
    
    for i=1:(n2-1)
        bw =  imdilate(bw, [1 1 1; 1 0 1; 1 1 1]);
    end
    
    mask = bw;
    
%     bw =  imdilate(mask, [1 1 1; 1 0 1; 1 1 1]);
%     bw =  imdilate(bw, [1 1 1; 1 0 1; 1 1 1])- mask;
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
       if max(max(t)) ==0
           continue;
       end
       [r,c] = find(t);
      
       x1 = min(c);
       y1 = min(r);
       x2 = max(c);
       y2 = max(r);
       
       width = x2-x1;
       height = y2-y1;
       if (width <=0 || height <=0)
           continue;
       end
       widths(i) = width;
       heights(i) = height;

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
       
       
        nf = sum(sum(pm(y1:y2, x1:x2)));
          %search for max until mass < 80% of nf
       maxx = 0;
       maxl = -inf;
       for xx = x1:x2-1
           m = sum(sum(pm(y1:y2, xx:x2)))/nf;
           if m<0.7
               break;
           end
           line = sum(bw(:,xx))/(y2-y1);
           if line>maxl
               maxl = line;
               maxx = xx;
           end
           
       end
       x1 = maxx;
       maxx = 0;
       maxl = -inf;
       for xx = x2:-1:(x1-1)

           m = sum(sum(pm(y1:y2, x1:xx)))/nf;
           if m<0.7
               break;
           end
           line = sum(bw(:,xx))/(y2-y1);
           if line>maxl
               maxl = line;
               maxx = xx;
           end
           
       end
       x2=maxx;
       
       
       
       
       
       
       
       
       
       
      
       np = np + 1;
      
       boundingBoxes(:, np) = [ x1,y1, x2,y2];
       
    end
    
    boundingBoxes = boundingBoxes(:, 1:np);
end


