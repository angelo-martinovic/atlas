function [df_Wout, df_W, df_Wbot, df_Wcat] = backpropTree(synCat,Wout,W,Wbot,Wcat,imgTree,thisNode,deltaUp,params)
%imgTree.plotTree()
df_Wbot = 0;
df_Wcat = 0;

thisNodeAct = imgTree.nodeFeatures(:,thisNode); %semantic vector of this node

% Wout
df_Wout = thisNodeAct';     %This looks like we have delta=1

deltaDownAddSyn = Wout'.*(thisNodeAct .* (1 - thisNodeAct));    %Delta propagated from the score
deltaDownFull = deltaUp+deltaDownAddSyn;    %Delta propagated from the upper level of the backprop tree + the score delta

%%% Wcat
if imgTree.cost %&& synCat==2   --- if this is a correct tree
    target = imgTree.nodeLabels(:,thisNode);    %desired label outputs
    if any(target)
        target  = target./sum(target );
        delta_cats = (imgTree.catOut(:,thisNode)-target);   %difference between prediction and desired output
        df_Wcat = delta_cats*[ thisNodeAct' 1]; % Wcat update
        deltaDownAddCat = Wcat' * delta_cats .*([thisNodeAct ;1] .* (1 - [thisNodeAct ;1]));    %Delta propagated from the label prediction
        deltaDownAddCat = deltaDownAddCat(1:params.numHid); %Selecting only numHid elements, unnecessary I'd say
        deltaDownFull = deltaDownFull - deltaDownAddCat;    %Subtracting delta? Probably because it's the correct tree.
    end
end

%Get the 2 children of the node
kids = imgTree.getKids(thisNode);
kidsActLR{1} = imgTree.nodeFeatures(:,kids(1)); %semantic vectors of children
kidsActLR{2} = imgTree.nodeFeatures(:,kids(2));
kidsAct = [kidsActLR{1} ;kidsActLR{2} ; 1]; %their cumulative activation
df_W =  deltaDownFull*kidsAct'; %update for W with the delta

W_x_deltaUp = (W'*deltaDownFull); % W*delta for both kids
Wd_bothKids = W_x_deltaUp(1:2*params.numHid);
Wd_bothKids= reshape(Wd_bothKids,params.numHid,2);  %Wd is split into two error messages...

for c = 1:2
    deltaDown= Wd_bothKids(:,c) .* (kidsActLR{c} .* (1 - kidsActLR{c})); %... propagated to each child
    
    %If the child has no more descendants
    if imgTree.isLeaf(kids(c))
        %Evaluate the labels
        target = imgTree.nodeLabels(:,kids(c));
        if imgTree.cost && any(target)  %If this is the correct tree
            thisKidAct = imgTree.nodeFeatures(:,kids(c));   %Get the predicted labels
            target  = target./sum(target);
            delta_cats = (imgTree.catOut(:,kids(c))-target);    %Get the delta (prediction-target)
            
            df_Wcat = df_Wcat+ delta_cats*[ thisKidAct' 1]; %Update for the Wcat
            deltaDownAddCat = Wcat' * delta_cats .*([thisKidAct;1] .* (1 - [thisKidAct;1])); %Delta propagated through Wcat
            
            deltaDownAddCat = deltaDownAddCat(1:params.numHid);
            deltaDown = deltaDown - deltaDownAddCat;    %Again subtracting? I guess it's because it's the correct tree.
        end
        
        %update for the Wbot
        df_Wbot = df_Wbot + deltaDown * [imgTree.leafFeatures(kids(c),:) 1];        
    else
	    %Recursively propagate the errors to the child and let it find 
	    %the updates for the parameters
        [df_Wout_new, df_W_new, df_Wbot_new,df_Wcat_new] = backpropTree(synCat,Wout,W,Wbot,Wcat,imgTree,kids(c),deltaDown,params);
        %Add the child's updates to your own
        df_Wout = df_Wout + df_Wout_new ;
        df_Wbot = df_Wbot + df_Wbot_new ;
        df_W = df_W + df_W_new;
        df_Wcat = df_Wcat + df_Wcat_new;
    end
    
    
end
