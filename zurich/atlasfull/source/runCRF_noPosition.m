function [result,E_begin,E_end] = runCRF_noPosition(cacheLocation,segMap,detectionMaps,positionMap,imageName,fold,beta,img,hyperParams)
    addpath('GCMex2.3/');

    %% Image size
    H = size(segMap,1);
    W = size(segMap,2);
    
    %% Learned weight vector
    w = hyperParams.w;

    %% Initial labels
    segclass = zeros(W*H,1);

    %% Pairwise term
    filename = [cacheLocation 'fold' num2str(fold) '_adjacencies_' imageName '.mat'];
    i = zeros( 4*W*H-2*H-2*W,1);
    j = zeros( 4*W*H-2*H-2*W,1);
    s = ones( 4*W*H-2*H-2*W,1);
    s2 = ones( 4*W*H-2*H-2*W,1);
    m = W * H;
    n = W * H;
    count = 0;
    if ~exist(filename,'file')
        for row = 0:H-1
            for col = 0:W-1
                pixel = 1+ row*W + col;

                % Calculate the contrast between pixels
                rgb_1 = img(row+1,col+1,:);

                % Bottom
                if row+1 < H
                    count = count +1;
                    i(count) = pixel;
                    j(count)=1+col+(row+1)*W; 

                    rgb_2 = img(row+2,col+1,:);
                    diff = norm(reshape(rgb_1-rgb_2,1,3))^2;
                    s(count) = exp(-beta*diff);

                end
                % Top
                if row-1 >= 0
                    count = count +1; 
                    i(count) = pixel;
                    j(count)=1+col+(row-1)*W; 

                    rgb_2 = img(row,col+1,:);
                    diff = norm(reshape(rgb_1-rgb_2,1,3))^2;
                    s(count) = exp(-beta*diff);
                end 
                % Right
                if col+1 < W
                    count = count +1;  
                    i(count) = pixel;
                    j(count)=1+(col+1)+row*W; 

                    rgb_2 = img(row+1,col+2,:);
                    diff = norm(reshape(rgb_1-rgb_2,1,3))^2;
                    s(count) = exp(-beta*diff);
                end
                % Left
                if col-1 >= 0
                    count = count +1; 
                    i(count) = pixel;
                    j(count)=1+(col-1)+row*W; 

                    rgb_2 = img(row+1,col,:);
                    diff = norm(reshape(rgb_1-rgb_2,1,3))^2;
                    s(count) = exp(-beta*diff);
                end 

            end
        end

        save(filename,'i','j','s','s2','m','n');
    else
        load(filename);
    end
    
    % Contrast sensitive
    % pairwise1 = sparse(i,j,s,m,n);
    
    % Contrast insensitive
    pairwise2 = sparse(i,j,s2,m,n);
    

    %% Unary term
    unary = zeros(8,W*H);
    nDetectors = length(detectionMaps);
    
    unary_mat = -w(1)*log(segMap);
    
    for i=1:nDetectors
        unary_mat = unary_mat-w(i+1)*log(detectionMaps(i).detectionMap);
    end
    
   
    if any(positionMap(:))
        unary_pos = zeros(8,W*H);
        for i=1:8
            unary_pos(i,:) = reshape(-log(positionMap(:,:,i)'),1,W*H);

            unary(i,:) = reshape(unary_mat(:,:,i)',1,W*H)+...
                w(1+nDetectors+i)*unary_pos(i,:);
        end
        skip=8;
    else
        skip=0;
        for i=1:8
            

            unary(i,:) = reshape(unary_mat(:,:,i)',1,W*H);
        end
    end
    
    %% Label term
%     labelcost = ones (8,8);
%     labelcost(1:8+1:64) = 0;
    
    labelcost = hyperParams.labelCost;
%     figure(2);imagesc(w(1+nDetectors+1)*labelcost);colorbar;
%   colormap('hot');
%   set(gca,'YTickLabel',{'window' 'wall' 'balcony' 'door' 'roof' 'sky' 'shop' 'chimney'});
%   set(gca,'XTickLabel',{'window' 'wall' 'balcony' 'door' 'roof' 'sky' 'shop' 'chimney'});

    % Final expression
    pairwise = w(1+nDetectors+skip+1)*pairwise2;
%     pairwise = pairwise2;

	%% Calling the MEX file
    disp('Running the graph cut...');
    [labels,E,Eafter] = GCMex(segclass, double(unary), pairwise, double(labelcost),0);
    disp('Done.');
    labels = labels + 1;

    E_begin = E;
    E_end = Eafter;
    
    result = reshape(labels,W,H)';
end