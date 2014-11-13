% Sets up the parameters and evaluates the 3 layer approach on a (part of a) 
% single fold of a dataset
% dataset: haussmann or eTrims
% fold: [1..5]
% type: valid or eval
% nImages: [1..max]
function [result,confMatrix] = Run_LabelFold(dataset,fold,type,nImages)

if nargin<4
    error('Usage:  Run_LabelFold(dataset,fold,type,nImages)')
end

if strcmpi(dataset,'etrims')
    detectors = { 'window-generic' 'door-generic' 'car_side-generic' 'car_rear_front-generic'};
elseif strcmpi(dataset,'haussmann')
    detectors = { 'window-specific' 'door-specific'};
elseif strcmpi(dataset,'monge30') || strcmpi(dataset,'monge30rect') 
    detectors = { };
end

    % Old parameters for gould CRF - haussmann
%     w =[ 0.1380    0.5626    2.0671    1.9670;
%          0.1499    0.5429    2.2373    1.6980; 
%          0.1241    0.4628    1.5121    1.8575;
%          0.1515    0.5499    1.3159    2.1810;
%          0.1757    0.6434    1.6991    1.8439;
%         ];    

    % New parameters for SVM - haussmann
%     w =[ 
%         0.3695   0.5209    0.9460    1.9589
%         0.3548   0.5733    1.0419    2.2103
%         0.3440   0.4412    1.2195    2.0912
%         0.3704   0.5379    0.9347    2.2332
%         0.3594   0.5951    0.8236    1.9861
%      ];   
    % Old detectors, window + door - eTrims
%     w =[ 
%          0.4614   0.0387       0    1.9848;
%          0.4939   0.2131       0    2.1925
%          0.4221   0.2008       0    1.2614
%          0.4356   0.4089       0    2.0336
%          0.4859   0.1103       0    2.1370
%      ];   

%     % Window + car detectors - eTrims
%     w =[  
%         0.4545  0.2146   0.1962   0       2.0334
%         0.4197  0.3206   0.4300   0.0109  1.2528
%         0.4888  0.4982   0        0.4374  2.3350
%         0.4217  0.2433   0.0984   0.2787  1.9444
%         0.4751  0.2347   0.1493   0       2.2323
%      ];  
 
 % Window + doors + car detectors - eTrims
%     w =[   
%         0.4508  0.3046  1.3213    0.1981   0       2.0879
%         0.4884  0.5725  0.0910    0        0.4357  2.3438
%         0.4166  0.3419  0.4202    0.4531   0.0099  1.2883
%         0.4176  0.3180  -0.0876   0.0728   0.2862  1.9577
%         0.4626  0.4898  0.5661    0.1509   0       2.2376
%      ];  

    % eTrims averaged
%     w =[
%         0.4472    0.4054    0.4622    0.1750    0.1464    1.9831
%         0.4472    0.4054    10.4622    0.1750    0.1464    1.9831
%         0.4472    0.4054    0.4622    0.1750    0.1464    1.9831
%         0.4472    0.4054    0.4622    0.1750    0.1464    1.9831
%         0.4472    0.4054    0.4622    0.1750    0.1464    1.9831
%     ];

 % Window + doors + car detectors , learned on training and valid - eTrims
%     w =[       
%         0.4400    0.3424    0.3104    0.2259    0.2927    2.1360    
%         0.4622    0.4258    0.3016    0.2749    0.3500    2.1661
%         0.4212    0.2656    0.2261    0.1743    0.2868    1.6208
%         0.4728    0.3860    0.2458    0.2597    0.2611    1.8946
%         0.4645    0.3938    0.2712    0.2164    0.3909    1.8980
%      ];  
 
%     w=[];


if strcmpi(dataset,'etrims')
    load(['cache_eTrims_train/fold' num2str(fold) '_w.mat'],'w');
    load(['cache_eTrims_train/fold' num2str(fold) '_labelCost.mat'],'labelCost');
elseif strcmpi(dataset,'haussmann')
    load(['cache_haussmann_valid/fold' num2str(fold) '_w.mat'],'w');
    load(['cache_haussmann_train/fold' num2str(fold) '_labelCost.mat'],'labelCost');
elseif strcmpi(dataset,'monge30') || strcmpi(dataset,'monge30rect') 
    load(['cache_haussmann_valid/fold' num2str(fold) '_w.mat'],'w');
    load(['cache_haussmann_train/fold' num2str(fold) '_labelCost.mat'],'labelCost');
    w=[w(1); w(4:end)];
end

% w=[w(1:5); zeros(8,1); w(end)];

 nClasses = 8;
 
 if strcmpi(dataset,'etrims')
    ignoreClasses = [0];
 elseif strcmpi(dataset,'haussmann')
    ignoreClasses = [0 8];
 elseif strcmpi(dataset,'monge30') || strcmpi(dataset,'monge30Rect')
    ignoreClasses = [0 8];
 end

 if strcmpi(dataset,'etrims')
[result,confMatrix] = LabelFold('eTrims', type, fold, ...
    '/esat/sadr/amartino/gould/testEtrimsJournal/', ...
    '/users/visics/amartino/RNN_link/RNN/data/detections_eTrims/',...
    detectors, 'SVM_cv', nImages, nClasses, ignoreClasses, w, labelCost);

elseif strcmpi(dataset,'haussmann')
[result,confMatrix] = LabelFold('haussmann', type, fold, ...
    '/esat/sadr/amartino/gould/testMeanShiftNew/', ...
    '/users/visics/amartino/RNN_link/RNN/data/detections_haussmann/',...
    detectors, 'SVM_cv', nImages, nClasses, ignoreClasses, w, labelCost);

elseif strcmpi(dataset,'monge30') 
[result,confMatrix] = LabelFold('monge30', type, fold, ...
    '/esat/sadr/amartino/gould/testMonge30/', ...
    '/users/visics/amartino/RNN_link/RNN/data/detections_monge30/',...
    detectors, 'SVM_cv', nImages, nClasses, ignoreClasses, w, labelCost);
elseif strcmpi(dataset,'monge30Rect') 
[result,confMatrix] = LabelFold('monge30Rect', type, fold, ...
    '/esat/sadr/amartino/gould/testMonge30Rect/', ...
    '/users/visics/amartino/RNN_link/RNN/data/detections_monge30Rect/',...
    detectors, 'SVM_cv', nImages, nClasses, ignoreClasses, w, labelCost);
 
 end
end