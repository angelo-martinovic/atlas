% Function that calculates the cost and gradient for one image.
function [costImg gradImg] = computeRNNCostAndGrad(X,decodeInfo,dataImg,params)

[Wbot,W,Wout,Wcat] = stack2param(X, decodeInfo);

%%% find highest scoring image (forward prop)
topCorr=1;
imgTreeTop = parseImage(topCorr,Wbot,W,Wout,Wcat,dataImg,params);

% parsing correct image (forward prop)
topCorr=2;
imgTreeCorr = parseImage(topCorr,Wbot,W,Wout,Wcat,dataImg,params);

if isnan(imgTreeCorr.cost) || isnan(imgTreeTop.cost)
    costImg =0;
    gradImg=0;
    disp('isnan(imgTreeCorr.cost) ?')
    return;
end

% backprop through the tree
thisStart = imgTreeTop.getTopNode();
deltaDown = zeros(params.numHid,1);
synCat=1;%unused, AFAIK

[df_Wout_top, df_W_top, df_Wbot_top, ~] = backpropTree(synCat,Wout,W,Wbot,Wcat,imgTreeTop,thisStart,deltaDown,params);

thisStart = imgTreeCorr.getTopNode();
[df_Wout_corr, df_W_corr, df_Wbot_corr, df_Wcat_corr] = backpropTree(synCat,Wout,W,Wbot,Wcat,imgTreeCorr,thisStart,deltaDown,params);

%From max margin : 1. element is the score of the correct tree
%2. element is its cost (errors in label prediction)
%3.element is the score of a proposal tree (score+loss)
costImg = -imgTreeCorr.score + imgTreeCorr.cost + imgTreeTop.score;

%Gradients for the parameters are going away from the correct tree and
%towards the proposal tree, because we want to move in the opposite
%direction of the gradient.
df_Wbot = -df_Wbot_corr + df_Wbot_top;
df_W    = -df_W_corr    + df_W_top;
df_Wout = -df_Wout_corr + df_Wout_top;

%Errors in category prediction are updated through the correct tree
df_Wcat = df_Wcat_corr;
[gradImg,~] = param2stack(df_Wbot,df_W,df_Wout,df_Wcat);
