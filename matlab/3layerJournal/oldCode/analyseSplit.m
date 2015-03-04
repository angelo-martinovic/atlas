function D = analyseSplit
    fold =2;
    chimney=8;
    window =1;
    balcony = 3;
    door=4;
    
    sky = 6;
    roof=5;
    facade = 2;
    shop =7;
    D = zeros(100,1);
    
    for i=1:20
        %close all;
        name = ['new/markus_ECP_valid_fold_' int2str(fold) '_img_' int2str(i) '.mat'];
        load (name)

       
       % D = probDensity(sky, labels);
        D = D + probDensity(sky, labels);
        
%         out =zeros(size(outImg));
%         remMask = zeros(size(labels));
%         win = (labels ==window);
%         win =  imdilate(win, [1 1 1; 1 0 1; 1 1 1]);
%         win =  imdilate(win, [1 1 1; 1 0 1; 1 1 1]);
%         remMask(win) = 1;
%         balc = (labels ==balcony);
%         balc =  imdilate(balc, [1 1 1; 1 0 1; 1 1 1]);
%         balc =  imdilate(balc, [1 1 1; 1 0 1; 1 1 1]);
%         remMask(balc) = 1;
%         doo = (labels ==door);
%         doo =  imdilate(doo, [1 1 1; 1 0 1; 1 1 1]);
%         doo =  imdilate(doo, [1 1 1; 1 0 1; 1 1 1]);
%         remMask(doo) = 1;
%         chm = (labels ==chimney);
%         chm =  imdilate(chm, [1 1 1; 1 0 1; 1 1 1]);
%         chm =  imdilate(chm, [1 1 1; 1 0 1; 1 1 1]);
%         remMask(chm) = 1;
% 
%         
%         mask = (labels ==roof);
%         probDensity(sky, labels, remMask);
%         [y1, y2] = findBoundaries(sky, labels, remMask);
%         
%         out(y1:y2,:) = sky;
%         
%         [y1, y2] = findBoundaries(roof, labels, remMask);
%         out(y1:y2,:) = roof;
%         
%         [y1, y2] = findBoundaries(facade, labels, remMask);
%         out(y1:y2,:) = facade;
%         
%         [y1, y2] = findBoundaries(shop, labels, remMask);
%         
%         out(y1:y2,:) = shop;
%         figure;subplot(1,2,1);imagesc(labels);
%         subplot(1,2,2);imagesc(out);
%         
                
        
        
        
        
    end


end

function C = probDensity(cl, label, remMask)
    delmask =zeros(size(label));
    mask = (label ==cl);
    
    %figure;imagesc(mask);
    
    B = imresize(mask, [100 100])
    C = sum(B,2);
    

end


function [y1,y2] = findBoundaries(cl, outImg, remMask)



    delmask =zeros(size(outImg));
    mask = (outImg ==cl);
    noOfRegionPixels = sum(sum(mask));
    y1 = min(find(sum(mask,2) ));
    x1 = 1;
    x2 = size(mask,2);
    y2 = max(find(sum(mask,2) ));
  
    
    
    delmask = mask;
    [conComp, n] = bwlabel(mask);
    delmask =  imerode(delmask, [1 1 1; 1 0 1; 1 1 1]);
    delmask =  imerode(delmask, [1 1 1; 1 0 1; 1 1 1]);
    
    delmask(:) = mask(:) - delmask(:);
    
    if sum(sum(mask(1,:))) > 0
       delmask(1,:) = mask(1,:);
       y1 =1; 
    end
    if sum(sum(mask(size(mask,1),:))) > 0
       y2 =size(mask,1); 
       delmask(y2,:) = mask(y2,:);
    end
    
    %delete confusing boundaries
   
    delmask(remMask>0) = 0;
    %figure; imagesc(delmask);
    %hold on;
    
  
      

  
   %modify min bounding rectangle
   %change upper boundary
   maxR = 0;
   for y = y1:y2+1
       ratioBorderPixel = sum(delmask(y,:))/(x2-x1);
       if ratioBorderPixel > maxR
           maxR = ratioBorderPixel;
           y1 = y;
       end

       noOfRegionPixels = sum(sum(mask));
       if sum(sum(mask(1:y,:)))/noOfRegionPixels < 0.9
           continue;
       end
       if sum(sum(mask(y:end,:)))/noOfRegionPixels < 0.5
           break;
       end
   end

   %change lower boundary
   maxR = 0;
   for y = y2:-1:y1-1
       ratioBorderPixel = sum(delmask(y,:))/(x2-x1);
       if ratioBorderPixel > maxR
           maxR = ratioBorderPixel;
           y2 = y;
       end
       noOfRegionPixels = sum(sum(mask));
       

       
       if sum(sum(mask(1:y,:)))/noOfRegionPixels < 0.5
           break;
       end
   end

    
    %line([x1 x2],[y1 y1],'LineWidth',4,'Color',[.11 .98 .98]);  
    %line([x1 x2],[y2 y2],'LineWidth',4,'Color',[.11 .98 .98]);  
       
    
    
 

end