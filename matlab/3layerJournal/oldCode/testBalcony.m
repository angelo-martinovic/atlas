
function testBalcony(a)
    close all;
    load('markus_15.mat')
    mask = (outImg ==3);
    figure(123); axis image;
    imagesc(mask);
    bw =  imdilate(mask, [1 1 1; 1 0 1; 1 1 1]);
    bw =  imdilate(bw, [1 1 1; 1 0 1; 1 1 1])- mask;
    hold on
    [conComp, n] = bwlabel(mask);
    w = [];
    p = zeros(4,n); np=0;
    for i=1:n

       t = (conComp ==i);
       [r,c] = find(t);
       %ypos = sum(r,1)/size(r,1);
       %xpos = sum(c,1)/size(c,1);
       x1 = min(c);
       y1 = min(r);
       x2 = max(c);
       y2 = max(r);
       w(i) = x2-x1;
       h(i) = y2-y1;
 
      
       np = np + 1;
      
       p(:, np) = [ x1,y1, x2,y2];
       
    end
    
    p = p(:, 1:np);
    %p = splitMergedBB(p);
    

    
   PM = sgmp(:,:,3);%
   PM = imfilter(sgmp(:,:,3), fspecial('gaussian',20,20));
   figure(333) ; imagesc(PM); axis image;
   %dd is the alignment distance threshold set to half the mean bb size
   ddw =median(w)*4;
   ddh = median(h)*4;
   p = updateBBBasedOnPM(p,bw,ddw,ddh);

  for k=1:size(p,2)
       
       x = round(p(1,k));
       y = round(p(2,k));
       w = round(p(3,k)-p(1,k));
       h = round(p(4,k)-p(2,k));
       X =[x, x+w, x+w,x+w,x+w,x, x,x];
       Y =[y, y,y, y+h, y+h,y+h, y+h, y];
       line(X,Y,'LineWidth',4,'Color',[.11 .98 .98]);

       
   end
   
   
   p2 = fminunc(@(p) objfunBalcony(p,PM,ddw, ddh), p);
   %p2=p;
   figure(555); imagesc(origImg); axis image;
   hold on
  
%    p2 = removeStupidPoints(p2,PM,ddw, ddh);
   
   for k=1:size(p2,2)
       
       x = round(p2(1,k));
       y = round(p2(2,k));
       w = round(p2(3,k)-p2(1,k));
       h = round(p2(4,k)-p2(2,k));
       X =[x, x+w, x+w,x+w,x+w,x, x,x];
       Y =[y, y,y, y+h, y+h,y+h, y+h, y];
       line(X,Y,'LineWidth',4,'Color',[.11 .98 .98]);

       
   end
%    [vs, maxvs]= similarityVoting(origImg, p2');
%    newmax = findnewMaxima(vs,p2,w,h,maxvs);
%    p2 = [p2 newmax];
%   
%     figure(554); imagesc(origImg); axis image;
%    hold on
%    for k=1:size(p2,2)
%        
%        x = round(p2(1,k));
%        y = round(p2(2,k));
%        w = round(p2(3,k)-p2(1,k));
%        h = round(p2(4,k)-p2(2,k));
%        X =[x, x+w, x+w,x+w,x+w,x, x,x];
%        Y =[y, y,y, y+h, y+h,y+h, y+h, y];
%        line(X,Y,'LineWidth',4,'Color',[.11 .98 .98]);
% 
%        
%    end
%     
% 
%     p2 = fminunc(@(p) objfun3(p2,PM,ddw, ddh), p2);
%     p2 = removeStupidPoints(p2,PM, ddw, ddh);
%     p2 = fminunc(@(p) objfun3(p2,PM,ddw, ddh), p2);
%    figure(556); imagesc(origImg); axis image;
%    hold on
%    for k=1:size(p2,2)
%        
%        x = round(p2(1,k));
%        y = round(p2(2,k));
%        w = round(p2(3,k)-p2(1,k));
%        h = round(p2(4,k)-p2(2,k));
%        X =[x, x+w, x+w,x+w,x+w,x, x,x];
%        Y =[y, y,y, y+h, y+h,y+h, y+h, y];
%        line(X,Y,'LineWidth',4,'Color',[.11 .98 .98]);
% 
%        
%    end
%    
%    
%    
%    
    
    
    
end


