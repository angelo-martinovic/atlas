function cga_code  = CreateCGA(fold,imageNr )
%CREATECGA Summary of this function goes here
%   Detailed explanation goes herecd RNN
    cga_code = '';
    
    dataLocation = '/users/visics/mmathias/devel/3layerJournal/current_best/';
    outputMat = [dataLocation 'haussmann_sampling_40_set_eval_fold_' num2str(fold) '_image_' num2str(imageNr) ...
            '_dataweight_' num2str(80) '_gridweight_' num2str(5) '.mat' ];
        
    load(outputMat);
    labels = output;
        
%     load('labels.mat','labels');
    figure(111);imagesc(labels);
    
    height = size(labels,1);
    width = size(labels,2);
    
    %% Roof-wall-shop layer
    [i,~]=find(labels==2);
    upWall = min(i); botWall  = max(i);
    
    [i,~]=find(labels==5);
    upRoof = min(i); botRoof  = max(i);
    
    [i,~]=find(labels==6);
    botSky  = max(i);
    
    [i,~]=find(labels==7);
    upShop = min(i);
    
    shopHeight = height - upShop;
    wallHeight = botWall - upWall;
    roofHeight = botRoof - upRoof;
    
    facadeHeight = shopHeight+wallHeight+roofHeight;
    labels = labels(height-facadeHeight:end,:);
    
    heightToWidthRatio = facadeHeight/width;
    nonRoofRatio = (shopHeight+wallHeight)/facadeHeight;
    
    cga_code = [cga_code 'Lot --> extrude(scope.sx*' num2str(heightToWidthRatio) ') Mass' '\n'];
    cga_code = [cga_code 'Building --> split(y){''' num2str(nonRoofRatio) ': BuildingMass | ''' num2str(1-nonRoofRatio) ': NIL}\n'];
    
     	
    
    cga_code = [cga_code 'S_wall --> split(y){''' ...
         num2str(shopHeight/facadeHeight) ': Shop | ''' ...
         num2str(wallHeight/facadeHeight) ': Wall | '''...
         num2str(roofHeight/facadeHeight) ': Roof'...
         '}\n'];
    
    layersAll = cell(0);
    %% Extend windows to connecting balconies
    labels2 = labels;
    
    windowCCP = bwconncomp(labels==1);
    balconyCCP = bwconncomp(labels==3);
    
    nWin = windowCCP.NumObjects;
    nBalc = balconyCCP.NumObjects;
    
    for i=1:nWin
       objectPixels = windowCCP.PixelIdxList{i};

       [y,x] = ind2sub(size(labels),objectPixels);
       topY = min(y); topX = min(x);
       botY = max(y); botX = max(x);
       for j=1:nBalc
           objectPixels = balconyCCP.PixelIdxList{j};

           [y,x] = ind2sub(size(labels),objectPixels);
           topY2 = min(y); topX2 = min(x);
           botY2 = max(y); botX2 = max(x);
           
           % Check if balcony is neighboring
           if abs(topY2-botY)<5 && ( (topX+5>=topX2 && topX<=botX2+5)||((botX+5>=topX2 && botX<=botX2+5)) )
               % Extend the window
               labels2(topY:botY2,topX:botX)=1;
           end

       end
    end
    figure(112);imagesc(labels2);
    layersAll{1} = (labels2==1);
    layersAll{3} = (labels==3);
    layersAll{4} = (labels==4);
    
    
    %% Things' layers
    labelNames = {'Window' 'Wall' 'Balcony' 'Door' 'Roof' 'Sky' 'Shop'};
    for label=[1 3 4]
        layer = layersAll{label}; 
       
        % How many rows in the grid
        ver = sum(layer,2);
        ver = ver/max(ver);
        ver=[0;ver;0];
%         lowerBoundaries = find(conv(ver,[-1 1])>0);
%         upperBoundaries = find(conv(ver,[1 -1])>0);
        [maxtab,mintab] = peakdet(smooth(conv(ver,[-1 1],'full')),0.02);
        
        maxtab = maxtab(abs(maxtab(:,2))>0.05);
        mintab = mintab(abs(mintab(:,2))>0.035);
        
        lowerBoundaries = round(maxtab)-1;
        upperBoundaries = round(mintab)-1;

        if length(lowerBoundaries)~=length(upperBoundaries)
            error(['Could not estimate ' labelNames{label} ' rows']);
        end

        % First row without elements
        firstSkip = facadeHeight - lowerBoundaries(end) - 1;

        if firstSkip<=1
            cga_code_element = ['S_' labelNames{label} ' --> split(y){'];
        else
            cga_code_element = ['S_' labelNames{label} ' --> split(y){''' ...
             num2str(firstSkip/facadeHeight) ': NIL | '];
        end

        for i=1:length(lowerBoundaries)
            % Determine start and end point of the window row
            lowRow = facadeHeight - lowerBoundaries(end-i+1);
            upRow = facadeHeight - upperBoundaries(end-i+1);

            if lowRow<1,lowRow=1; end; if lowRow>facadeHeight, lowRow=facadeHeight;end;
            if upRow<1,upRow=1; end; if upRow>facadeHeight, upRow=facadeHeight;end;
                    
            rowHeight = upRow - lowRow;

            cga_code_element = [cga_code_element '''' num2str(rowHeight/facadeHeight) ': Row_' labelNames{label} '_' num2str(i) ' | '];

            %% Element row
            elementRow = layer(upperBoundaries(end-i+1):lowerBoundaries(end-i+1)-1,:);

            % How many columns in the row
            hor = sum(elementRow,1);
            hor = hor/max(hor);
            hor=[0,hor,0];
%             leftBoundaries = find(conv(hor,[1;-1])>0);
%             rightBoundaries = find(conv(hor,[-1;1])>0);
            
            [maxtab,mintab] = peakdet(smooth(conv(hor,[-1 1],'full')),0.1);
        
            maxtab = maxtab(abs(maxtab(:,2))>0.1);
            mintab = mintab(abs(mintab(:,2))>0.1);
        
            leftBoundaries = round(mintab);
            rightBoundaries = round(maxtab);
        
            if rightBoundaries(1)==1
                rightBoundaries = rightBoundaries(2:end);
            end
            if leftBoundaries(end)>=size(elementRow,2)
                leftBoundaries = leftBoundaries(1:end-1);
            end
            if length(leftBoundaries)~=length(rightBoundaries)
                error('Could not estimate window columns');
            end

            firstSkip = leftBoundaries(1) - 1;
            if firstSkip<=1
                cga_code_row = ['Row_' labelNames{label} '_' num2str(i) ' --> split(x){'];
            else
                cga_code_row = ['Row_' labelNames{label} '_' num2str(i) ' --> split(x){''' ...
                 num2str(firstSkip/width) ': NIL | '];
            end
        
         
            for j=1:length(leftBoundaries)
                 % Determine start and end point of the element row
                leftCol = leftBoundaries(j);
                rightCol = rightBoundaries(j);
                
                if leftCol<1,leftCol=1; end; if leftCol>width, leftCol=width;end;
                if rightCol<1,rightCol=1; end; if rightCol>width, rightCol=width;end;

                colWidth = rightCol - leftCol;

                cga_code_row = [cga_code_row '''' num2str(colWidth/width) ': ' labelNames{label} ' | '];

                %% Determine start and end point of the space between element rows
                if j<length(leftBoundaries)
                    nextLeftCol = leftBoundaries(j+1);
                else
                    nextLeftCol = width;
                end

                spaceWidth = nextLeftCol - rightCol - 1;
                if spaceWidth>0

                    if j~=length(leftBoundaries)
                        cga_code_row = [cga_code_row '''' num2str(spaceWidth/width) ': NIL | '];
                    else
                        cga_code_row = [cga_code_row '''' num2str(spaceWidth/width) ': NIL}'];
                    end
                else
                    cga_code_row = [cga_code_row(1:end-2) '}'];
                end

            end
            cga_code = [cga_code '\n' cga_code_row];


            %% End element row
            %% Determine start and end point of the space between window rows
            if i<length(lowerBoundaries)
                nextLowRow = facadeHeight - lowerBoundaries(end-i);
            else
                nextLowRow = facadeHeight;
            end

            spaceHeight = nextLowRow - upRow - 1;

            if spaceHeight>0
                if i~=length(lowerBoundaries)
                    cga_code_element = [cga_code_element '''' num2str(spaceHeight/facadeHeight) ': NIL | '];
                else
                    cga_code_element = [cga_code_element '''' num2str(spaceHeight/facadeHeight) ': NIL}'];
                end
            else
                cga_code_element = [cga_code_element(1:end-2) '}'];
            end
        end
        cga_code = [cga_code '\n' cga_code_element];
    
    end
    


     %% Output
    cga_code = sprintf(cga_code);
%     disp(cga_code);
end

