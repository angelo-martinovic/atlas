
function test(a)
    close all;
    load('markus_21.mat')
    mask = (outImg ==1);
    figure(123); axis image;
    imagesc(mask);
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
       x2 = max(c)+1;
       y2 = max(r)+1;
       w(i) = x2-x1;
       h(i) = y2-y1;
 
      
       np = np + 1;
      
       p(:, np) = [ x1,y1, x2,y2];
       
    end
    
    p = p(:, 1:np);
    p = splitMergedBB(p);
    

    
   PM = sgmp(:,:,1);%imfilter(sgmp, fspecial('gaussian',2,20));
   figure(333) ; imagesc(PM); axis image;
   %dd is the alignment distance threshold set to half the mean bb size
   ddw =median(w)/2.0;
   ddh = median(h)/2.0;
  
   p2 = fminunc(@(p) objfun3(p,PM,ddw, ddh), p);
   figure(555); imagesc(origImg); axis image;
   hold on
  
   p2 = removeStupidPoints(p2,PM,ddw, ddh);
   
   for k=1:size(p2,2)
       
       x = round(p2(1,k));
       y = round(p2(2,k));
       w = round(p2(3,k)-p2(1,k));
       h = round(p2(4,k)-p2(2,k));
       X =[x, x+w, x+w,x+w,x+w,x, x,x];
       Y =[y, y,y, y+h, y+h,y+h, y+h, y];
       line(X,Y,'LineWidth',4,'Color',[.11 .98 .98]);

       
   end
   [vs, maxvs]= similarityVoting(origImg, p2');
   newmax = findnewMaxima(vs,p2,w,h,maxvs);
   p2 = [p2 newmax];
  
    figure(554); imagesc(origImg); axis image;
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
    

    p2 = fminunc(@(p) objfun3(p2,PM,ddw, ddh), p2);
    p2 = removeStupidPoints(p2,PM, ddw, ddh);
    p2 = fminunc(@(p) objfun3(p2,PM,ddw, ddh), p2);
   figure(556); imagesc(origImg); axis image;
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

function w=qualityShape(thisIdx, conComp, probMap)
    thisreg = conComp==thisIdx;
    thisArea = sum(sum(thisreg));
    [r,c] = find(thisreg);
    x1 = min(c);
    y1 = min(r);
    x2 = max(c)+1;
    y2 = max(r)+1;
    w = x2 - x1;
    h = y2 -y1;
    w = thisArea/(w*h);


end

function w = qualityVertAlign(thisIdx, conComp,indices, probMap)
    thisreg = conComp==thisIdx;
    thisfactor = sum(probMap(thisreg))/sum(sum(thisreg));
    [r,c] = find(thisreg);
    miny = min(c)
    maxy = max(c)
    w = 0;
    for i=1:size(indices,2)
        if (thisIdx ~= indices(i))
            tmp = conComp==indices(i);
            factor = sum(probMap(tmp))/sum(sum(tmp));
            factor =1;
            [r2,c2] = find(tmp);
            w1 = distweight(abs(miny-min(c2)));
            w2 = distweight(abs(maxy-max(c2)));
            w = w+factor*(w1+w2);
        end
    end
    w=w*thisfactor;
end

function w = qualityHorrAlign(thisIdx, conComp,indices, probMap)
    thisreg = conComp==thisIdx;
    thisfactor = sum(probMap(thisreg))/sum(sum(thisreg));
    [r,c] = find(thisreg);
    miny = min(r)
    maxy = max(r)
    w = 0;
    for i=1:size(indices,2)
        if (thisIdx ~= indices(i))
            tmp = conComp==indices(i);
            factor = sum(probMap(tmp))/sum(sum(tmp));
            factor =1;
            [r2,c2] = find(tmp);
            w1 = distweight(abs(miny-min(r2)));
            w2 = distweight(abs(maxy-max(r2)));
            w = w+factor*(w1+w2);
            
        end
    end
    w=w*thisfactor;
end

function weight = distweight(d)

    weight = gaussmf(d,[7,0]);

end
