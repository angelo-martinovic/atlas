function newmax = findnewMaxima(vs,p2,maxvs)
    maxcount = 0;
    th = 0.2
    newmax = zeros(4,1);
    mvs = maxvs/10
   vss = (vs>mvs) .* vs;
   vss = (vss>th) .* vss;
   bw = vss > imdilate(vss, [1 1 1; 1 0 1; 1 1 1]);
   [yy,xx] = find(bw);

   for i=1:size(yy,1)
        ccw =  0;
        cch = 0;
        widths = [];
        heights = [];
        %find aligning bbxs
        for j=1:size(p2,2)
            x = p2(1,j);
            y = p2(2,j);
            w = p2(3,j) - x;
            h = p2(4,j) -y;
           if abs((x+w/2)-xx(i)) < w
               ccw = ccw+1;
              widths(ccw) = w; 
           end
           if abs((y+h/2)-yy(i)) < h
               cch = cch+1;
              heights(cch) = h; 
           end
        end
        if size(widths,1) ==0 
            bbwidth = median(w);
        else
            bbwidth = median(widths);    
        end
        if size(heights,1) ==0 
            bbheight = median(h);
        else
            bbheight = median(heights);
        end
        
        
        bbnew = zeros(4,1);
        bbnew(1) = xx(i) - bbwidth/2;
        bbnew(2) = yy(i) - bbheight/2;
        bbnew(3) = bbnew(1) + bbwidth;
        bbnew(4) = bbnew(2) + bbheight;
        maxcount = maxcount +1;
        newmax(:,maxcount) = bbnew;
        
      
   end
   

   
   
end
