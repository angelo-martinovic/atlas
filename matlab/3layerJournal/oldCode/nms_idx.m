function ind = nms_idx(indices, boxes,value_equal_class, value_different_class)
rem = zeros(1, size(indices,2));
value = 0;
for i=1:size(indices,2)
    ia = indices(i);
    a = boxes(:,ia);
    %            x11 = boxes(1,ia);
    %            y11 = boxes(2,ia);
    %            x21 = boxes(3,ia);
    %            y21 = boxes(4,ia);
    label = boxes(5,ia);
    for j=1:size(indices,2)
        jb = indices(j);
        
        %             if (label ~=  boxes(5,jb))
        %                continue;
        %             end
        if i<j
            b = boxes(:,jb);
            %                x12 = boxes(1,jb);
            %                y12 = boxes(2,jb);
            %                x22 = boxes(3,jb);
            %                y22 = boxes(4,jb);
            ol = bb_overlap(a,b);
            %union = (bb_area(a) +bb_area(b)) - ol;
            minarea = min(bb_area(a) ,bb_area(b));
            if (label ~=  boxes(5,jb))
                value = value_different_class;
            else
                value = value_equal_class;
                if (label == 3)
                    value = 0.7;
                end
            end
            if ol/minarea> value
                rem(j)=rem(j)+1;
            end
        end
        
        
    end
end
ind = indices(rem==0);



end