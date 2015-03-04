function bbout = updateMapsbySymmetryAndBB(bb, pms,x, idx,ddw,ddh, deleteOverlapping)
    imwidth = size(pms,2);
    imheight = size(pms,1);
    bb= bb(:, bb(1,:) > 0 & bb(3,:)>0 & bb(2,:) > 0 & bb(4,:) >0 & bb(3,:) <= imwidth & bb(4,:) <=imheight)
    bbout = zeros(4,1);
    cc = 0;
    w = size(pms(:,:,1),2);
    %get all bb left and right of x
    bbleft = bb(:,bb(3,:) < x);
    bbright= bb(:,bb(1,:) > x);
    %keep the bounding boxes of the centre
    for i=1:size(bb,2)
        if bb(1,i) <= x  && bb(3,i) >= x
           cc = cc+1;
           bbout(:,cc) = bb(:,i);
        end
    end
    
    %mirror the bounding boxes on x
    bbleftm = bbleft;
    bbrightm = bbright;
    bbleftm(1,:) = x+ (x-bbleft(3,:));
    bbleftm(3,:) = x + (x-bbleft(1,:));
    
    bbrightm(1,:) = x - (bbright(3,:)-x);
    bbrightm(3,:) = x - (bbright(1,:)-x);
    
    %remove the ones outside the image
     rightm =  bbrightm(3,:) <=w & bbrightm(1,:) >0
     for i=1:size(rightm,2)
         if rightm(i) ==0
            %keep assymetric bounding boxes
            cc = cc+1;
            bbout(:,cc) = bbright(:,i);
             
         end
     end
     bbright = bbright(:,rightm);
     bbrightm = bbrightm(:,rightm);

     %remove the ones outside the image
     leftm =  bbleftm(3,:) <=w & bbleftm(1,:) >0
     for i=1:size(leftm,2)
         if leftm(i) ==0
            %keep assymetric bounding boxes
            cc = cc+1;
            bbout(:,cc) = bbleft(:,i);
             
         end
     end
     bbleft = bbleft(:,leftm);
     bbleftm = bbleftm(:,leftm);
     
    
    
    %find overlapping BB 
    bbrightmtmp = zeros(4,1);
    bbrighttmp = zeros(4,1);
    cc1 =0;
    for j=1:size(bbrightm,2)
    
        overlap = false;
        for i=1:size(bb,2)    
            ol = getOverlap(bb(:,i), bbrightm(:,j));
            if ol(1) > 0 && ol(2) > 0
                overlap = true;
                break;
            else
                overlap=false;
              
            end
            
           
        end
         if overlap==false
                cc1= cc1+1;
                bbrightmtmp(:,cc1) = bbrightm(:,j);
                bbrighttmp(:,cc1) = bbright(:,j)
         else
           cc = cc+1;
           bbout(:,cc) = bbrightm(:,j);
           cc = cc+1;
           bbout(:,cc) = bb(:,i);
         end
    end
    bbrightm = bbrightmtmp;
    bbright = bbrighttmp;
    if cc1 ==0
        bbrightm =[];
        bbright = [];
%     else
%          rightm = bbright(3,:) <= w & bbrightm(3,:) <=w & bbright(1,:) >0 & bbrightm(1,:) >0
%          bbright = bbright(:,rightm);
%          bbrightm = bbrightm(:,rightm);
%         cc = cc+1;
%         bbout(:,cc) = bbright(:,rightm);
    end
   
    
    bbleftmtmp = zeros(4,1);
    bblefttmp = zeros(4,1);
    cc1 =0;
    for j=1:size(bbleftm,2)
 
        overlap= false;
        for i=1:size(bb,2)       
            ol = getOverlap(bb(:,i), bbleftm(:,j));
            if ol(1) > 0 && ol(2) > 0
                overlap = true;
                break;
            else
                overlap=false;
              
            end
            
        end
         if overlap==false
                cc1= cc1+1;
                bbleftmtmp(:,cc1) = bbleftm(:,j);
                bblefttmp(:,cc1) = bbleft(:,j);
         else
           cc = cc+1;
           bbout(:,cc) = bbleftm(:,j);   
           cc= cc+1;
           bbout(:,cc) = bb(:,i);
         end
    end
    bbleftm = bbleftmtmp;
    bbleft = bblefttmp;
    if cc1(1) ==0
        bbleftm =[];
           bbleft = [];
%     else
%    
%         leftm = bbleft(3,:) <= w & bbleftm(3,:) <=w & bbleft(1,:) >0 & bbleftm(1,:) >0
%    
%         bbleft = bbleft(:,leftm);
%         bbleftm = bbleftm(:,leftm);     
%         
%         cc = cc+1;
%         bbout(:,cc) = bbleft(:,leftm);
    end
    
    
    

    %delete bb outside the image
   
    %bbleftm = bbleftm(:,bbleftm(3,:) <= w);
    %bbrightm =bbrightm(:,bbrightm(1,:) > 0);
    
    %decide to add the mirrored bb or to remove the original
    for i=1:size(bbleft,2)
        if bbleftm(3,i) > w
            cc = cc+1;
            bbout(:,cc) = bbleft(:,i);
            continue;
        end
        prmassleft = pms(round(bbleft(2,i)):round(bbleft(4,i)), round(bbleft(1,i)):round(bbleft(3,i)), :);
        prmassleft = sum(sum(prmassleft,1),2);
        prmassleftm = pms(round(bbleftm(2,i)):round(bbleftm(4,i)),round( bbleftm(1,i)):round(bbleftm(3,i)), :);
        prmassleftm = sum(sum(prmassleftm,1),2);
        t1 = sort(prmassleft, 'descend');
        t2 = sort(prmassleftm, 'descend');
        if (t1(1) >= t2(1))
            %add mirrored bb
            cc = cc+1;
            bbout(:,cc) = bbleft(:,i);
            cc = cc+1;
            bbout(:,cc) = bbleftm(:,i);
        else
            
            cc = cc+1;
            bbout(:,cc) = bbleft(:,i);
            %remove bb nothing to do here
        end
        
        
      
    end
    for i=1:size(bbright,2)
        if bbrightm(1,i) < 1
            cc = cc+1;
            bbout(:,cc) = bbright(:,i);
            continue;
        end
        prmassright = pms(round(bbright(2,i)):round(bbright(4,i)), round(bbright(1,i)):round(bbright(3,i)), :);
        prmassright = sum(sum(prmassright,1),2);
        prmassrightm = pms(round(bbrightm(2,i)):round(bbrightm(4,i)), round(bbrightm(1,i)):round(bbrightm(3,i)), :);
        prmassrightm = sum(sum(prmassrightm,1),2);
        t1 = sort(prmassright, 'descend');
        t2 = sort(prmassrightm, 'descend');
        if (t1(1) >= t2(1))
            %add mirrored bb
            cc = cc+1;
            bbout(:,cc) = bbright(:,i);
            cc = cc+1;
            bbout(:,cc) = bbrightm(:,i);
        else
            %remove bb 
             cc = cc+1;
            bbout(:,cc) = bbright(:,i);
        end

        
        
        
    end
    %check overlap and 
   if (deleteOverlapping ==1)
    bbout = removeOverlappingBB(bbout, pms(:,:,idx),ddw,ddh);
   end
      





end

function pnew = removeOverlappingBB(p, PM, ddw, ddh)
    
    for i = 1 : size(p,2)
       w = round(p(3,i)-p(1,i));
       h = round(p(4,i)-p(2,i));
       
   
        for j =1 : size(p,2)
            if i==j
                continue;
            end


            if(checkOverlap(p(:,i), p(:,j)) > 0)
                pt = [p(:,1:i-1) p(:,i+1:end)]
                pt2 = [p(:,1:j-1) p(:,j+1:end)]
                e1 = objfun3(pt,PM, ddw,ddh)
                e2 = objfun3(pt2,PM,ddw, ddh)
                if e1 > e2
                    pnew = removeOverlappingBB(pt2,PM,ddw,ddh);
                    return;
                else
                    pnew = removeOverlappingBB(pt,PM,ddw,ddh);
                    return;
                end
       
            end
       
        end   
    end
    pnew = p;
    
    
end
function overlap = checkOverlap(b1, b2)
    
    overlap = rectint([b1(1) b1(2) (b1(3)-b1(1)) (b1(4)-b1(2))],[b2(1) b2(2) (b2(3)-b2(1)) (b2(4) -b2(2))])
    if overlap > 0
        overlap
    end


    
end
function e = distanceQuality(p1,p2)

    x1 = p1(1);
    y1 = p1(2);
    w1 = p1(3) -x1;
    h1 = p1(4) - y1;
    cx1 = x1+w1/2;
    cy1 = y1+h1/2;
    
    x2 = p2(1);
    y2 = p2(2);
    w2 = p2(3) -x2;
    h2 = p2(4) - y2;
    cx2 = x2+w2/2;
    cy2 = y2+h2/2;
    e = false;
    if (abs(cx1 - cx2) < 1.5 * w1) && abs(cy2 -cy1) < 1.2*h1
        e = true
        
    end
    

end
    
    
