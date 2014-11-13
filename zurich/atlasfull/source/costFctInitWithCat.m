% Function we are trying to minimize

%   ALGORITHM DESCRIPTION

%   FIRST PART
%    1. We take the good label pairs, propagate them forward and calculate
%   the difference in the category labels.
%   2. We backpropagate the errors through Wcat and W.
%   3. We calculate the labels for all segments, calculate the differences,
%   and backpropagate through Wcat.
%   4. We use both backpropagated errors to update Wbot.
%   SECOND PART
%   5. We use good pair - bad pair strategy to calculate the differences
%   in the score. If the network is scoring correctly, no error is
%   propagated.
%   6. We backpropagate the errors through Wout, W and Wbot.
%   7. We sum all the gradients: Wcat from first part, Wout from second part
%   and W, Wbot from both parts of the algorithm, adding regularization.
function [cost,grad,catRightBot,catTotalBot,catRightTop,catTotalTop] = costFctInitWithCat(X,...
    decodeInfo,goodPairsL,goodPairsR,badPairsL,badPairsR,onlyGoodL,onlyGoodR,onlyGoodLabels,...
    onlyGoodDistributions,allSegs,allSegLabels,allSegDistributions,params)

cost=0;
% Get the parameters from "stack"
[Wbot,W,Wout,Wcat] = stack2param(X, decodeInfo);

numOnlyGood = length(onlyGoodLabels);   %Number of neighboring segment pairs with the same label
numAll = length(allSegLabels);  %Number of all segments
onlyGoodBotL= (1./(1 + exp(-Wbot* onlyGoodL)));   %Semantic representations of left children
onlyGoodBotR= (1./(1 + exp(-Wbot* onlyGoodR)));   %Semantic representations of right children
onlyGoodBotA= (1./(1 + exp(-Wbot* allSegs)));     %Semantic representations of all segments

%Now we calculate the semantic representations of the segment combinations
%by forward propagation
onlyGoodHid = (1./(1 + exp(-W * [onlyGoodBotL; onlyGoodBotR; ones(1,numOnlyGood)])));   %Ones are there to include the bias from W
%Calculate the probabilities of labels based on the semantic representation, ones are there for the bias
catHid = Wcat * [onlyGoodHid ; ones(1,numOnlyGood)];
catOut = softmax(catHid);

%For each column - good segment pair, a '1' is put into the row that corresponds to the
%label of the first segment.
% target = zeros(params.numLabels,numOnlyGood);
% target(sub2ind(size(target),onlyGoodLabels,1:numOnlyGood))=1;
target = onlyGoodDistributions ./ repmat(sum(onlyGoodDistributions),params.numLabels,1) ;

%For each column -segment, a '1' is put into the row that corresponds to 
%the label .
% targetA = zeros(params.numLabels,numAll);
% targetA(sub2ind(size(targetA),allSegLabels,1:numAll))=1;

% From pixel counts to distributions
targetA = allSegDistributions ./ repmat(sum(allSegDistributions),params.numLabels,1) ;

%catOuts are vectors with elements between 0 and 1. Their logarithms will
%be negative. The cost for the wrong label is the negative logarithm of the
%prediction. (e.g. the right label is 3, and catOut has probability 1 for
%label 3, cost is 0; if prob=0, cost = infinity)
cost = cost  -sum(sum(target.*log(catOut)));

%The predicted label is the one with maximal probability.
[~, classOut] = max(catOut);

catRightTop = sum(classOut==onlyGoodLabels); %Number of hits
catTotalTop = length(classOut); %Total number of label calculations
deltaCatTop = (catOut-target);  %Difference between prediction and truth

%This should be the backpropagation part
%%% df_Wcat
df_Wcat =  deltaCatTop * [ onlyGoodHid' ones(numOnlyGood,1)];   %Error * semantic vector

deltaDownCatTop = Wcat' * deltaCatTop .*([ onlyGoodHid ;ones(1,numOnlyGood)] .* (1 - [ onlyGoodHid ;ones(1,numOnlyGood)])); %Delta propagated through Wcat
deltaDownCatTop= deltaDownCatTop(1:params.numHid,:);    %Select the first numHid rows - seems unnecessary

%%% df_W
df_W = deltaDownCatTop*[onlyGoodBotL; onlyGoodBotR; ones(1,numOnlyGood)]';  %Error propagated from Wcat * semantic vectors

%Delta propagated through W
deltaDownTop = (W'*deltaDownCatTop) .* ([onlyGoodBotL; onlyGoodBotR; ones(1,numOnlyGood)] .* (1 - [onlyGoodBotL; onlyGoodBotR; ones(1,numOnlyGood)])); 
%We split the error and propagate it to the children
deltaDownTopL = deltaDownTop(1:params.numHid,:);
deltaDownTopR = deltaDownTop(params.numHid+1:2*params.numHid,:);

% now the kids!
%

%Calculating label predictions from children
catHidL = Wcat * [onlyGoodBotL ; ones(1,numOnlyGood)];
catHidR = Wcat * [onlyGoodBotR ; ones(1,numOnlyGood)];
catHidA = Wcat * [onlyGoodBotA ; ones(1,numAll)];

catOutL = softmax(catHidL);
catOutR = softmax(catHidR);
catOutA = softmax(catHidA);

% target is the same as for the merged!
cost = cost -sum(sum(target.*log(catOutL)));    %we further penalize wrong categories for children
cost = cost -sum(sum(target.*log(catOutR)));    
costA = -sum(sum(targetA.*log(catOutA)));   %different score for AllPairs
%Selecting output labels
[~, classOutL] = max(catOutL);
[~, classOutR] = max(catOutR);
[~, classOutA] = max(catOutA);
catRightBot = 0           +sum(classOutL==onlyGoodLabels);  %number of hits
catRightBot = catRightBot +sum(classOutR==onlyGoodLabels);
catRightBot = catRightBot +sum(classOutA==allSegLabels);
catTotalBot = length(classOutL)+length(classOutR)+length(classOutA);    %total evaluations of labels

deltaCatBotL = (catOutL-target);    %Errors in label estimation
deltaCatBotR = (catOutR-target);
deltaCatBotA = (catOutA-targetA);

%%% df_Wcat
df_Wcat =  df_Wcat + deltaCatBotL * [ onlyGoodBotL' ones(numOnlyGood,1)]; %More error to df_Wcat
df_Wcat =  df_Wcat + deltaCatBotR * [ onlyGoodBotR' ones(numOnlyGood,1)];
df_WcatA =  deltaCatBotA * [onlyGoodBotA' ones(numAll,1)]; %df_WcatA is separate

deltaDownCatL = Wcat' * deltaCatBotL .*([ onlyGoodBotL ;ones(1,numOnlyGood)] .* (1 - [ onlyGoodBotL ;ones(1,numOnlyGood)])); %Delta propagated through Wcat
deltaDownCatR = Wcat' * deltaCatBotR .*([ onlyGoodBotR ;ones(1,numOnlyGood)] .* (1 - [ onlyGoodBotR ;ones(1,numOnlyGood)]));
deltaDownCatA = Wcat' * deltaCatBotA .*([ onlyGoodBotA ;ones(1,numAll)] .* (1 - [ onlyGoodBotA ;ones(1,numAll)]));

deltaDownCatL =deltaDownCatL(1:params.numHid,:); %Unnecessary
deltaDownCatR =deltaDownCatR(1:params.numHid,:);
deltaDownCatA =deltaDownCatA(1:params.numHid,:);

deltaFullDownL = deltaDownCatL+deltaDownTopL; % Total error is the sum of propagated error from the parent + self error
deltaFullDownR = deltaDownCatR+deltaDownTopR;
% these are just single segs
deltaFullDownA = deltaDownCatA;

%%% df_Wbot
% propagating back through Wbot
df_Wbot = deltaFullDownL * onlyGoodL';  %Left-hand children
df_Wbot = df_Wbot +  deltaFullDownR * onlyGoodR';   %Add right-hand children
df_WbotA = deltaFullDownA * allSegs';   %Only for single segments

%%% final cost and derivatives of categories
%When we were analyzing pairs, we had three evaluations of Wcat error (one
%for parent and twice for children). When we were analyzing single
%segments, Wcat error was evaluated once. Therefore, we find the total
%error by combining these two errors with the ratio 1:3. Same goes for cost.
cost = 1./(3* numOnlyGood)  * cost + 1./numAll * costA; 
df_Wcat_CAT = 1./(3 * numOnlyGood)  * df_Wcat + 1./numAll * df_WcatA;  
df_W_CAT = 1./(3 * numOnlyGood) * df_W; %For df_W, we use only the good pairs - although here I don't know why we divide by 3
df_Wbot_CAT = 1./(3 * numOnlyGood)  * df_Wbot + 1./numAll * df_WbotA; %mixing again for df_Wbot - although here I think the ratio should be 1:2

%Now's the tricky part...

% forward prop all segment features into the hidden/"semantic" space
goodBotL = (1./(1 + exp(-Wbot* goodPairsL)));   %Propagating good pairs
goodBotR = (1./(1 + exp(-Wbot* goodPairsR)));
badBotL = (1./(1 + exp(-Wbot* badPairsL)));     %Propagating bad pairs
badBotR = (1./(1 + exp(-Wbot* badPairsR)));

numGoodAll = size(goodBotL,2);  %These two should be the same, I think
numBadAll = size(badBotL,2);

% forward prop the pairs and compute scores
goodHid = (1./(1 + exp(-W * [goodBotL ; goodBotR ; ones(1,numGoodAll)])));
badHid  = (1./(1 + exp(-W * [badBotL ; badBotR ; ones(1,numBadAll)])));

scoresGood = Wout*goodHid;  %Score for a good pair
scoresBad = Wout*badHid;    %Score for a bad pair

% compute cost
costAll = 1-scoresGood+scoresBad;   %We want the good score to be better than bad score
ignoreGBPairs = costAll<0;  %if scoresGood>scoresBad+1

%Ignoring the GB pairs where scores are as we want them - high for good and
%low for bad pairs.
costAll(ignoreGBPairs)  = [];
goodBotL(:,ignoreGBPairs) = [];
goodBotR(:,ignoreGBPairs) = [];
badBotL(:,ignoreGBPairs) = [];
badBotR(:,ignoreGBPairs) = [];
goodHid(:,ignoreGBPairs) = [];
badHid(:,ignoreGBPairs)  = [];
goodPairsL(:,ignoreGBPairs)  = [];
goodPairsR(:,ignoreGBPairs)  = [];
badPairsL(:,ignoreGBPairs)  = [];
badPairsR(:,ignoreGBPairs)  = [];

%numAll is now the length of the remaining pairs.
numAll = length(costAll);

%And now we add the positive costs (not ignored) to the total cost
%Also adding the regularization term.
cost = cost + 1./length(ignoreGBPairs) * sum(costAll(:)) + params.regPTC/2 * (sum(Wbot(:).^2) +sum(W(:).^2) +sum(Wout(:).^2) +sum(Wcat(:).^2));

%Calculating the df_Wout by summing all good semantic vectors and
%subtracting that from the sum of all bad semantic vectors
df_Wout =-sum(goodHid,2)' +  sum(badHid,2)';

% subtract good neighbors:
delta4 = bsxfun(@times,Wout',(goodHid .* (1 - goodHid)));   %Delta that propagates back towards W
df_W = -delta4 * [goodBotL ; goodBotR ; ones(1,numAll)]';   %Calculating the df_W

delta3 =(W'*delta4) .* ([goodBotL ; goodBotR ; ones(1,numAll)] .* (1 - [goodBotL ; goodBotR ; ones(1,numAll)]));    %Delta that propagates back towards Wbot
delta3L = delta3(1:params.numHid,:);    %Splitting the error messages for left and right children
delta3R = delta3(params.numHid+1:2*params.numHid,:);

df_Wbot = - delta3L * goodPairsL';      %Calculating the df_Wbot for left and right children
df_Wbot = df_Wbot - delta3R * goodPairsR';

% add bad neighbors - similar procedure, but signs are inverted
delta4 = bsxfun(@times,Wout',(badHid .* (1 - badHid)));
df_W = df_W +  delta4 * [badBotL ; badBotR ; ones(1,numAll)]';

delta3 =(W'*delta4) .* ([badBotL ; badBotR ; ones(1,numAll)] .* (1 - [badBotL ; badBotR ; ones(1,numAll)]));
delta3L = delta3(1:params.numHid,:);
delta3R = delta3(params.numHid+1:2*params.numHid,:);

df_Wbot = df_Wbot +  delta3L * badPairsL';
df_Wbot = df_Wbot +  delta3R * badPairsR';


% add category's derivatives and regularizer
df_Wcat = df_Wcat_CAT + params.regPTC * Wcat;   %From the first part and regularizer

df_Wbot = df_Wbot_CAT  + 1./length(ignoreGBPairs) * df_Wbot + params.regPTC * Wbot; %From the first part, adding the second and regularizer
df_W    = df_W_CAT  + 1./length(ignoreGBPairs) * df_W    + params.regPTC * W; %From the first part, adding the second and regularizer
df_Wout = 1./length(ignoreGBPairs) * df_Wout + params.regPTC * Wout;    %Second part and regularizer

%We output the gradient parameters
[grad,~] = param2stack(df_Wbot,df_W,df_Wout,df_Wcat);