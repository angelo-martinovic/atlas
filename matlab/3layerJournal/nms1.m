function bb_out = nms1(bb, value_equal_class, value_different_class, ol_matrix, min_area_matrix)

    value = 0;
    rem = zeros(1, size(bb,2));
    for i=1:size(bb,2)
            a = bb(:,i); 
       for j=i+1:size(bb,2)

           b = bb(:,j);
           ol = ol_matrix(a(7), b(7));
           %ol2 = bb_overlap(a,b);
           %assert(ol == ol2);
           if ol ==0
               continue;
           end
           %minarea2 = min(bb_area(a) ,bb_area(b));
           minarea = min_area_matrix(a(7), b(7));
           %assert(minarea2 == minarea);
           if a(5) ~=b(5)
               value = value_different_class;
           else
               value = value_equal_class;
               if (a(5) == 3)
                    value = 0.7;
                end
           end
               
           if ol/minarea> value
              rem(j)=rem(j)+1;
          
           end
           
           
       end
    end
    bb_out = bb(:,~(rem>0));
    
end