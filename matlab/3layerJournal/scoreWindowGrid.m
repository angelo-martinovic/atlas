function score = scoreWindowGrid(boxes_in, hyperParameters)

    all_align_score = 0;
    
    for label=hyperParameters.objClasses
        %align_score = 0;
        boxes = boxes_in(:,boxes_in(5,:) == label);
    
        
        %new
%         align_score = 0;
%         for k=1:size(boxes,2)-1
%             %alignv = 1;
%             %alignh = 1;
%             x11 = boxes(1,k);
%             y11 = boxes(2,k);
%             x21 = boxes(3,k);
%             y21 = boxes(4,k);
%            
%             
%             for j=k+1:size(boxes,2)
%                 
%                 x12 = boxes(1,j);
%                 y12 = boxes(2,j);
%                 x22 = boxes(3,j);
%                 y22 = boxes(4,j);
%                
%                    
%                 if abs(x11-x12) < hyperParameters.win_ddw
%                     align_score = align_score -2;
% 
% 
%                 end
%                 %if b<0
%                 if abs(y11-y12) < hyperParameters.win_ddh
%                     align_score = align_score -2;
% 
% 
%                 end
%                % if c<0
%                 if abs(x21-x22) < hyperParameters.win_ddw
%                     align_score = align_score -2;
% 
%                 end
%                % if d<0
%                 if abs(y21-y22) < hyperParameters.win_ddh
%                     align_score = align_score -2;
% 
%                 end
% 
%              
%             end
%            
%         end
       
        aw = [pdist(boxes(1,:)') pdist(boxes(3,:)')]<hyperParameters.win_ddw;
        ah = [pdist(boxes(2,:)') pdist(boxes(4,:)')]<hyperParameters.win_ddh;
        
        align_score = -2 * sum([aw ah]);
        
        if size(boxes,2) > 0
            all_align_score = all_align_score + align_score/size(boxes,2);
        else
            all_align_score = all_align_score + align_score ;
        end
        
    end
    score = all_align_score;
end