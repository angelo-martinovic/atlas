function outMap = labelGrid(setHorLines, setVerLines, totalConfidenceMap)

height = size(setHorLines,2);
width = size(setVerLines,2);

%bar(setHorLines);
%figure; bar(setVerLines);
horLines = setHorLines>0;
verLines = setVerLines>0;

% compH = bwlabel(horLines);
% compV = bwlabel(verLines);
% 
% centroidsH = regionprops(compH,'Centroid');
% centroidsV = regionprops(compV,'Centroid');
% 
% centroidsH = centroidsH(2:end-1);
% centroidsV = centroidsV(2:end-1);

gridH = find(horLines==1);%zeros(1,size(centroidsH,1));
gridV = find(verLines==1);%zeros(1,size(centroidsV,1));

% 
% for i=1:size(centroidsH,1)
%     gridH(i) = round(centroidsH(i).Centroid(1));
% end
% for i=1:size(centroidsV,1)
%     gridV(i) = round(centroidsV(i).Centroid(1));
% end

maxtabHor = gridH';
maxtabVer = gridV';

%figure;imagesc(zeros(height,width));
for iteration = 1:1
    outMap = zeros(height,width);

    windowList = cell(0);
    balconyList = cell(0);
    shopList = cell(0);
    
    windowListSize = 0;
    balconyListSize = 0;
    shopListSize = 0;
    
    if (size(maxtabHor,1)>1)
        for i=1:size(maxtabHor,1)-1
            begLineHor = maxtabHor(i);
            endLineHor = maxtabHor(i+1)-1; 
            if (endLineHor==height-1) 
                endLineHor = height; 
            end
            if (endLineHor-begLineHor<0)
                continue;
            end

            if (size(maxtabVer,1)>1)
                for j=1:size(maxtabVer,1)-1
                    begLineVer = maxtabVer(j);
                    endLineVer = maxtabVer(j+1)-1;  
                    if (endLineVer==width-1) 
                        endLineVer = width; 
                    end
                    if (endLineVer-begLineVer<0)
                        continue;
                    end
                    
                    %[~,indexImg] = max(totalConfidenceMap(begLineHor:endLineHor,begLineVer:endLineVer,:),[],3);

                    score1 = sum(sum(totalConfidenceMap(begLineHor:endLineHor,begLineVer:endLineVer,1)));
                    score2 = sum(sum(totalConfidenceMap(begLineHor:endLineHor,begLineVer:endLineVer,2)));
                    score3 = sum(sum(totalConfidenceMap(begLineHor:endLineHor,begLineVer:endLineVer,3)));
                    score4 = sum(sum(totalConfidenceMap(begLineHor:endLineHor,begLineVer:endLineVer,4)));
                    score5 = sum(sum(totalConfidenceMap(begLineHor:endLineHor,begLineVer:endLineVer,5)));
                    score6 = sum(sum(totalConfidenceMap(begLineHor:endLineHor,begLineVer:endLineVer,6)));
                    score7 = sum(sum(totalConfidenceMap(begLineHor:endLineHor,begLineVer:endLineVer,7)));
                    score8 = sum(sum(totalConfidenceMap(begLineHor:endLineHor,begLineVer:endLineVer,8)));
                    
%                     score1 = sum(sum(indexImg ==1));
%                     score2 = sum(sum(indexImg ==2));
%                     score3=  sum(sum(indexImg ==3));
%                     score4 = sum(sum(indexImg ==4));
%                     score5 = sum(sum(indexImg ==5));
%                     score6 = sum(sum(indexImg ==6));
%                     score7 = sum(sum(indexImg ==7));
%                     score8 = sum(sum(indexImg ==8));
                    scores = [score1 score2 score3 score4 score5 score6 score7 score8];
                   
                    [~,indices] = sort(scores);
                    
%                     if (pos==1)
%                         windowListSize = windowListSize + 1;
%                         windowList{windowListSize,1} = [begLineVer begLineHor endLineVer endLineHor];
%                         windowList{windowListSize,2} = maxScore;  
%                         windowList{windowListSize,3} = 0;  
%                     end
%                     if (pos==3)
%                         balconyListSize = balconyListSize + 1;
%                         balconyList{balconyListSize,1} = [begLineVer begLineHor endLineVer endLineHor];
%                         balconyList{balconyListSize,2} = maxScore;  
%                         balconyList{balconyListSize,3} = 0;  
%                     end
%                      if (pos==4)
%                         shopListSize = shopListSize + 1;
%                         shopList{shopListSize,1} = [begLineVer begLineHor endLineVer endLineHor];
%                         shopList{shopListSize,2} = maxScore;  
%                         shopList{shopListSize,3} = 0;   
%                      end
                    outMap(begLineHor:endLineHor,begLineVer:endLineVer)=indices(end);
                   
                    %notSegElements = sum(sum(map(begLineHor:endLineHor,begLineVer:endLineVer)==0));

                    %if (segElements>notSegElements)

                    %else
                    %    outMap(begLineHor:endLineHor,begLineVer:endLineVer)=0;
                    %end
               
                end
            end

        end
    end
    %figure;imagesc(outMap);

%     windowList = sortrows(windowList,2);
%     windowList = flipud(windowList);
% 
%     if (balconyListSize>0)
%         balconyList = sortrows(balconyList,2);
%         balconyList = flipud(balconyList);
%     end
%     
%     if (shopListSize>0)
%         shopList = sortrows(shopList,2);
%         shopList = flipud(shopList);
%     end

% --WINDOWS---
     if (windowListSize>1)
        oldWindowList = windowList;
        oldWindowScore = 0;
        for it=1:min([windowListSize 10])
              %Select the first window
            firstSelectedIndex = it;%unidrnd(shopListSize,1);
            windowList{firstSelectedIndex,3} = 1;
            for i=1:windowListSize
                % Try to add current window.
                % Is rectangularity preserved?
                % (Return the difference between bbox and selected rectangles)
                    %Yes (difference = 0): Continue
                    %No: (difference > 0)
                        % Check if other elements BELOW the current one fill the gap
                        % EXACTLY
                            %Yes: Add all the other fillers, continue
                            %No: Remove current element
                %If current element is not already selected
                if (windowList{i,3} == 0)
                    %Try to select it
                    windowList{i,3} = 1;
                    selected = find(cell2mat(windowList(:,3))==1);
                    indexof = find(selected==i);
                    %Check rectangularity on all currently selected elements
                    differenceMap = checkRectangularity(height, width, windowList((cell2mat(windowList(:,3))==1)),indexof);
                    %Difference map is '1' if there is a discrepancy, '0' otherwise
                    %If there is some discrepancy
                    if (sum(sum(differenceMap))~=0)
                        %Try to find other non-selected elements which fill the hole
                        nextElements = windowList(1:windowListSize,:);
                        %Indices will be '1' if the element can be used in filling
                        indices = findExactFilling(differenceMap,nextElements);
                        if (sum(sum(indices))==0)
                            windowList{i,3} = 0;    %No filling found, remove current
                         else
                            selList = find(indices==1);
                            for j = 1:size(selList)
                                windowList{selList(j),3} = indices(selList(j)); %Select the others as well
                            end

                        end

                    else
                       %No discrepancy, element is added, go forward.
                    end
                end

            end
            windowScore = 0;
            for i=1:windowListSize
                rect = cell2mat(windowList(i,1));
                if (windowList{i,3}==1)
                    windowScore = windowScore + (rect(4)-rect(2))*(rect(3)-rect(1));
                end
            end
            if (windowScore>oldWindowScore)
                oldWindowScore=windowScore;
                oldWindowList = windowList;
            end
        end
        
        windowList = oldWindowList;
     end
     
     % - --- BALCONIES ----
    
     if (balconyListSize>1)
        oldBalconyList = balconyList;
        oldBalconyScore = 0;
        for it=1:min([balconyListSize 10])
              %Select the first balcony
            firstSelectedIndex = it;%unidrnd(shopListSize,1);
            balconyList{firstSelectedIndex,3} = 1;
            for i=1:balconyListSize
                % Try to add current balcony.
                % Is rectangularity preserved?
                % (Return the difference between bbox and selected rectangles)
                    %Yes (difference = 0): Continue
                    %No: (difference > 0)
                        % Check if other elements BELOW the current one fill the gap
                        % EXACTLY
                            %Yes: Add all the other fillers, continue
                            %No: Remove current element
                %If current element is not already selected
                if (balconyList{i,3} == 0)
                    %Try to select it
                    balconyList{i,3} = 1;
                    selected = find(cell2mat(balconyList(:,3))==1);
                    indexof = find(selected==i);
                    %Check rectangularity on all currently selected elements
                    differenceMap = checkRectangularity(height, width, balconyList((cell2mat(balconyList(:,3))==1)),indexof);
                    %Difference map is '1' if there is a discrepancy, '0' otherwise
                    %If there is some discrepancy
                    if (sum(sum(differenceMap))~=0)
                        %Try to find other non-selected elements which fill the hole
                        nextElements = balconyList(1:balconyListSize,:);
                        %Indices will be '1' if the element can be used in filling
                        indices = findExactFilling(differenceMap,nextElements);
                        if (sum(sum(indices))==0)
                            balconyList{i,3} = 0;    %No filling found, remove current
                         else
                            selList = find(indices==1);
                            for j = 1:size(selList)
                                balconyList{selList(j),3} = indices(selList(j)); %Select the others as well
                            end

                        end

                    else
                       %No discrepancy, element is added, go forward.
                    end
                end

            end
            balconyScore = 0;
            for i=1:balconyListSize
                rect = cell2mat(balconyList(i,1));
                if (balconyList{i,3}==1)
                    balconyScore = balconyScore + (rect(4)-rect(2))*(rect(3)-rect(1));
                end
            end
            if (balconyScore>oldBalconyScore)
                oldBalconyScore=balconyScore;
                oldBalconyList = balconyList;
            end
        end
        
        balconyList = oldBalconyList;
     end

    
     %SHOPS------------------------------------------%
    
    if (shopListSize>1)
        oldShopList = shopList;
        oldShopScore = 0;
        for it=1:min([shopListSize 10])
              %Select the first window
            firstSelectedIndex = it;%unidrnd(shopListSize,1);
            shopList{firstSelectedIndex,3} = 1;
            for i=1:shopListSize
                % Try to add current window.
                % Is rectangularity preserved?
                % (Return the difference between bbox and selected rectangles)
                    %Yes (difference = 0): Continue
                    %No: (difference > 0)
                        % Check if other elements BELOW the current one fill the gap
                        % EXACTLY
                            %Yes: Add all the other fillers, continue
                            %No: Remove current element
                %If current element is not already selected
                if (shopList{i,3} == 0)
                    %Try to select it
                    shopList{i,3} = 1;
                    selected = find(cell2mat(shopList(:,3))==1);
                    indexof = find(selected==i);
                    %Check rectangularity on all currently selected elements
                    differenceMap = checkRectangularity(height, width, shopList((cell2mat(shopList(:,3))==1)),indexof);
                    %Difference map is '1' if there is a discrepancy, '0' otherwise
                    %If there is some discrepancy
                    if (sum(sum(differenceMap))~=0)
                        %Try to find other non-selected elements which fill the hole
                        nextElements = shopList(1:shopListSize,:);
                        %Indices will be '1' if the element can be used in filling
                        indices = findExactFilling(differenceMap,nextElements);
                        if (sum(sum(indices))==0)
                            shopList{i,3} = 0;    %No filling found, remove current
                         else
                            selList = find(indices==1);
                            for j = 1:size(selList)
                                shopList{selList(j),3} = indices(selList(j)); %Select the others as well
                            end

                        end

                    else
                       %No discrepancy, element is added, go forward.
                    end
                end

            end
            shopScore = 0;
            for i=1:shopListSize
                rect = cell2mat(shopList(i,1));
                if (shopList{i,3}==1)
                    shopScore = shopScore + (rect(4)-rect(2))*(rect(3)-rect(1));
                end
            end
            if (shopScore>oldShopScore)
                oldShopScore=shopScore;
                oldShopList = shopList;
            end
        end
        
        shopList = oldShopList;
    end
   
        

    

   if (windowListSize>1)
    for i=1:windowListSize
        rect = cell2mat(windowList(i,1));
        if (windowList{i,3}==0)
            totalConfidenceMap(rect(2):rect(4),rect(1):rect(3),1) = 0;
            outMap(rect(2):rect(4),rect(1):rect(3))=2;
        end
    end
   end

    if (balconyListSize>1)
        for i=1:balconyListSize
            rect = cell2mat(balconyList(i,1));
            if (balconyList{i,3}==0)
                totalConfidenceMap(rect(2):rect(4),rect(1):rect(3),3) = 0;
                outMap(rect(2):rect(4),rect(1):rect(3))=2;
            end
        end
    end
    if (shopListSize>1)
     for i=1:shopListSize
        rect = cell2mat(shopList(i,1));
        if (shopList{i,3}==0)
            totalConfidenceMap(rect(2):rect(4),rect(1):rect(3),4) = 0;
            outMap(rect(2):rect(4),rect(1):rect(3))=2;
        end
     end
    end
end


    
end