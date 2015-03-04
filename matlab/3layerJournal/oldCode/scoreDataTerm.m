function energy = scoreDataTerm(sgmp, bboxes)
    locationLUT = zeros(size(sgmp,1),size(sgmp,2));
    boxes = round(bboxes);
    sgmp(sgmp==1) = 0.999999999;
 
    for k=1:size(boxes,2)
              
               topY =boxes(2,k); topX =boxes(1,k);
               botY =boxes(4,k); botX = boxes(3,k);
               
               locationLUT(topY:botY,topX:botX)=boxes(5,k);
    end
    
    energy = 0;
    for label=[1 3 4]
        if max(max(locationLUT==label)) == 0
            continue;
        end
       probMapLabel = sgmp(:,:,label);
       probMapNotLabel =( 1-probMapLabel);
       
       energy = energy +  sum(sum(-log(probMapLabel(locationLUT==label)))) + sum(sum(-log(probMapNotLabel(locationLUT~=label))));
       
%        energy = energy / (imgSize(1)*imgSize(2));
       
       
    end
     energy = energy / (size(locationLUT,1)*size(locationLUT,2));
   % energy = 0;

end