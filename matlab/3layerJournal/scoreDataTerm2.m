function energy = scoreDataTerm2(outImg, bboxes, hyperParameters)
    energy = 0;
   
    for label=hyperParameters.objClasses
        haslabel = 0;
        locationLUT = false(size(outImg,1),size(outImg,2));
        locationLUTelements = 0;
        boxes = round(bboxes);

        for k=1:size(boxes,2)

            topY = boxes(2,k); topX = boxes(1,k);
            botY = boxes(4,k); botX = boxes(3,k);

            if boxes(5,k)==label
                haslabel = 1;
                locationLUT(topY:botY,topX:botX)=true;
                locationLUTelements = locationLUTelements + (botY-topY+1)*(botX-topX+1);
            end
        end

%         if max(max(locationLUT==1)) == 0 || sum(sum(outImg==label)) ==0
%             continue;
%         end

        if ~haslabel 
            continue;
        end
        
        if all(outImg(:)~=label(:))
            continue;
        end
        
        probMapLabel = (outImg==label);

        mat1= locationLUT & probMapLabel;
        mat2=~locationLUT & probMapLabel;
        energy = energy -  sum(sum(mat1))/locationLUTelements +  sum(sum(mat2))/sum(sum(probMapLabel)) ;
      

    end


end