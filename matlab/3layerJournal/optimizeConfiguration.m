function [best_score, best_boxes] = optimizeConfiguration(boxes, pool, outImg, hyperParameters)
    
    id = 1:size(boxes,2);
    boxes = [boxes; id];
    id = size(boxes,2)+1:size(boxes,2)+size(pool,2);
    pool = [pool;id];
    
    % Find overlapping elements
    [ol_matrix, min_area_matrix]= create_ol_matrix(boxes,pool);
    
    % Remove overlapping elements
    [pool, ~] = nms(boxes, pool,0, 0.9, ol_matrix, min_area_matrix);
    
    f = @(x)TotalEnergy(x,boxes, pool, outImg, ol_matrix,min_area_matrix, hyperParameters);
    nvars = size(pool,2);
    lb_all = zeros(nvars,1);
    ub_all = ones(nvars,1);
    IntCon = 1:nvars;
                 
    optionsGA_noDisp = gaoptimset('Display','none','Generations',hyperParameters.ga.nGenerations );
    
    if nvars>0
        [optParams,~,~,~] = ga(f,nvars,[],[],[],[],lb_all,ub_all,[],IntCon,optionsGA_noDisp);
    
        best_boxes = [boxes pool(:,optParams==1)];
    else
        best_boxes = boxes;
    end
    best_boxes = nms1(best_boxes, 0, 0.9, ol_matrix, min_area_matrix);
    best_score = doScoring(best_boxes,outImg,hyperParameters);
end

% Function to minimize
function f = TotalEnergy(x,boxes,pool,outImg, ol_matrix, min_area_matrix,hyperParameters)

    tmp_boxes = [boxes pool(:,x==1)];
    tmp_boxes = nms1(tmp_boxes, 0, 0.9, ol_matrix, min_area_matrix);
    f = doScoring(tmp_boxes,outImg,hyperParameters);
   
end

% Creates the overlap matrix
function [res_ol, res_minarea] = create_ol_matrix(boxes,pool)
    
    all=[boxes pool];
    res_ol = zeros(size(all,2));
    res_minarea = zeros(size(all,2));
    for i=1:size(all,2)
           a = all(:,i);
           assert(i == a(7));
       for j=1:size(all,2)
           b = all(:,j);
           assert(j == b(7));
           ol = bb_overlap(a,b);
           res_ol(i,j) = ol;
           
           if ol ==0
               continue;
           end
           minarea = min(bb_area(a) ,bb_area(b));
           res_minarea(i,j) = minarea;
           
       end
    end

end
