function bla = SymmetryVoting(objects,sgmp)

    bla=0;

    imageSize = [size(sgmp,1) size(sgmp,2)];

    x_sample_freq = 1;
    y_sample_freq = 1;
    
    x = (-size(sgmp,2):x_sample_freq:size(sgmp,2));
    y = (-size(sgmp,1):y_sample_freq:size(sgmp,1));
    
    
    
    votingSpace = zeros(numel(y),numel(x));
    for i1=1:length(objects)
        for i2=1:length(objects)
            bbox1 = objects(i1).bbox;
            bbox2 = objects(i2).bbox;
            cent1 = struct('x',(bbox1(2)+bbox1(4))/2,'y',(bbox1(1)+bbox1(3))/2);
            cent2 = struct('x',(bbox2(2)+bbox2(4))/2,'y',(bbox2(1)+bbox2(3))/2);
            diffX = (cent1.x-cent2.x);
            diffY = (cent1.y-cent2.y);
            
            [~,x_bin] = min(abs(x-diffX));
            [~,y_bin] = min(abs(y-diffY));
            
            bSize = 0;
            votingSpace(y_bin-bSize:y_bin+bSize,x_bin-bSize:x_bin+bSize) =...
                votingSpace(y_bin-bSize:y_bin+bSize,x_bin-bSize:x_bin+bSize)+1;%+fspecial('gaussian', 2*bSize+1,bSize/2);
            
        end
    end

    [i,j]= find(votingSpace>0);
    
    bandwidth=10;
    data=[y(i');x(j')];
    

    tic
    [clustCent,point2cluster,clustMembsCell] = MeanShiftCluster(data,bandwidth);
    toc
    
%     fig=figure(111),clf,hold on;imagesc(x,y,votingSpace);
%     title('Clusters');
%     VisualizePoints(fig,clustCent);

    
    % Extract initial values of g1 and g2 (grid generators)
    tolerance = 5;
    
    columnClusters = clustCent(:,abs(clustCent(2,:))<tolerance & abs(clustCent(1,:))>tolerance);
    [~,pos] = min(abs(columnClusters(1,:)));
    g1Clust = columnClusters(:,pos);
    g1 = abs(g1Clust(1));
    
    rowClusters = clustCent(:,abs(clustCent(1,:))<tolerance & abs(clustCent(2,:))>tolerance);
    [~,pos] = min(abs(rowClusters(2,:)));
    g2Clust = rowClusters(:,pos);
    g2 = abs(g2Clust(2));
    
    disp([g1, g2]);
    
    [n1,n2] = GridDimensions(g1,g2,clustCent);
    
    disp([n1, n2]);
    
%     fig=figure(222);hold on;imagesc(x,y,votingSpace);
%     title('Grid');
%     VisualizeGrid(fig,g1,g2,n1,n2);
   
    initAlpha = ones(1, (2*n1+1) * (2*n2+1) );
    initBeta = ones(1,size(clustCent,2));
    
    f = @(xx)GridEnergy(xx,n1,n2,clustCent);
    
    lb = [10,10,zeros(size(initAlpha)),zeros(size(initBeta))];
    ub = [200,200,ones(size(initAlpha)),ones(size(initBeta))];
    
        
    opts1= optimset('display','off');
    tic;
    xx = lsqnonlin(f,[g1,g2,initAlpha,initBeta],lb,ub,opts1);
    toc;
    
    final_g1 = xx(1);
    final_g2 = xx(2);
    
    finalAlpha = xx(3:3+size(initAlpha,2)-1);
    finalBeta = xx(3+size(initAlpha,2):end);
    
    fig=figure(111); title('Clusters');clf,hold on;rectangle('Position',[min(x) min(y) 2*imageSize(2) 2*imageSize(1)]);
    VisualizePoints(fig,clustCent,1-finalBeta,final_g1,final_g2,n1,n2);
    
    fig=figure(222); title('Grid');clf,hold on;rectangle('Position',[min(x) min(y) 2*imageSize(2) 2*imageSize(1)]);
    VisualizeGrid(fig,final_g1,final_g2,n1,n2,1-finalAlpha);
end

function [n1,n2] = GridDimensions(g1,g2,clustCent)

    farthestY = max(abs(clustCent(1,:)));
    farthestX = max(abs(clustCent(2,:)));
    
    n1 = round(farthestY/g1);
    n2 = round(farthestX/g2);
   
end

function VisualizeGrid(fig,g1,g2,n1,n2,pointSizes)
    
    figure(fig);
    
    numGridElem = (2*n1+1)*(2*n2+1);
    if nargin<6
        pointSizes = ones(1,numGridElem);
    end
    cnt=0;
    for y=(-n1:1:n1)
        for x=(-n2:1:n2)
            if x<n2
                line([g2*x g2*(x+1)],[  g1*y g1*y ],'Color','k');
            end
            if y<n1
                line([g2*x g2*x],[  g1*y g1*(y+1) ],'Color','k');
            end
            cnt=cnt+1;
            plot(g2*x,g1*y,'o','MarkerEdgeColor','k',...
                'MarkerFaceColor',repmat(pointSizes(cnt),1,3), 'MarkerSize',10)
        end
    end
    
end

function VisualizePoints(fig,clustCent,pointSizes,g1,g2,n1,n2)

    figure(fig); hold on;
    numClust = size(clustCent,2);
    
    if nargin<3
        pointSizes = ones(1,numClust);
    end

    if nargin>3
        for y=(-n1:1:n1)
            for x=(-n2:1:n2)
                if x<n2
                    line([g2*x g2*(x+1)],[  g1*y g1*y ],'Color','k');
                end
                if y<n1
                    line([g2*x g2*x],[  g1*y g1*(y+1) ],'Color','k');
                end
            end
        end
    end
    
    for k = 1:min(numClust)
%         myMembers = clustMembsCell{k};
        myClustCen = clustCent(:,k);
        plot(myClustCen(2),myClustCen(1),'o','MarkerEdgeColor','k',...
            'MarkerFaceColor',repmat(pointSizes(k),1,3), 'MarkerSize',10)
    end
 
end

function [dist,c] = ClosestClusterCenter(i,j,g1,g2,clustCent)
    gridLocation = [g1*i;g2*j];
    
    distances = clustCent-gridLocation(:,ones(1,size(clustCent,2)));
    ssd = sum(distances.^2);
    
    [ssd,c] = min(ssd);
    dist = sqrt(ssd);
end

function [dist,i,j] = ClosestGridLocation(k,g1,g2,n1,n2,clustCent)
    clustLocation = clustCent(:,k);
    
    i = round(clustLocation(1)/g1);
    j = round(clustLocation(2)/g2);
    
    if i>n1
        i=n1;
    end
    
    if i<-n1
        i=-n1;
    end
    
    if j>n2
        j=n2;
    end
    
    if j<-n2
        j=-n2;
    end
    
    gridLocation = [g1*i;g2*j];
    ssd = sum((gridLocation-clustLocation).^2);
    dist = sqrt(ssd);
   
end

function E = GridEnergy(x,n1,n2,clustCent)

    gamma = 0.2;
    sqrtgamma = sqrt(gamma);
    sqrtoneminusgamma = sqrt(1-gamma);
    
    g1 = x(1);
    g2 = x(2);
    
    C = size(clustCent,2);
    
    eTermCount = 2* ((2*n1+1)*(2*n2+1) + C);
    E = zeros(eTermCount,1);
    
    cnt = 2;
    E_cnt=0;
    for i=-n1:1:n1
        for j=-n2:1:n2
            cnt=cnt+1;
            
            [dist,~]=ClosestClusterCenter(i,j,g1,g2,clustCent);
            
            E_cnt=E_cnt+1;
            E(E_cnt)=sqrtgamma*x(cnt)*dist;
            
            E_cnt=E_cnt+1;
            E(E_cnt)=sqrtoneminusgamma*(1-(x(cnt))^2);
            
        end
    end
    
    for i=1:C
        cnt = cnt+1;
        
        [dist,~,~]=ClosestGridLocation(i,g1,g2,n1,n2,clustCent);
        
        E_cnt=E_cnt+1;
        E(E_cnt)=sqrtgamma*x(cnt)*dist;
            
        E_cnt=E_cnt+1;
        E(E_cnt)=sqrtoneminusgamma*(1-(x(cnt))^2);
           
    end
    
    bla=sum(E.^2);
    
    if randi(5,1)==3
        disp(bla);
    end
%     if (bla<70)
%         disp('aha');
%     end
end