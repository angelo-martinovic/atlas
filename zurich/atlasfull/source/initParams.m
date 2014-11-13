%Initializing RNN parameters (theta in the paper)

fanIn = params.numFeat;     %Number of features - input vector size
range = 1/sqrt(fanIn);      %Range? Probably related to std dev.

%Creating the Wbot(input) matrix by generating uniformly distributed 
%random numbers from 0 to 1 and rescaling to [-range,range]
% INPUT: features, OUTPUT: semantic vector
Wbot = -range + (2*range).*rand(params.numHid,fanIn);
%Adding an extra column of zeros - bias
Wbot(:,end+1) = zeros(params.numHid,1);

fanIn = 2*params.numHid;    %Twice the size of the hidden layer size
range = 1/sqrt(fanIn);      %Again with the range
%Creating the W(recursive) matrix by generating uniformly distributed 
%random numbers and rescaling
% INPUT: 2 semantic vectors, OUTPUT: semantic vector
W = -range + (2*range).*rand(params.numHid,fanIn);
%Adding an extra column of zeros - bias
W(:,end+1) = zeros(params.numHid,1);

%Creating the Wout(score) matrix by generating gaussian distributed
%random numbers, and rescaling
% INPUT: semantic vector, OUTPUT: scalar double (score)
Wout = 0.08*randn(1,params.numHid);

% sparsify W a little
zeroOut = 17;%params.numHid * 35/100;
if zeroOut
    %For each row
    for i = 1:size(W,1)  
        %Select a random subset of columns
        makeZero = randperm(size(W,2));
        % There will be zeroOut of them, or at maximum width-3.
        % Set those elements to 0.
        W(i,makeZero(1:min(zeroOut,size(W,2)-3))) = 0;
    end
end


% Wcat
%Creating the Wcat(labels) matrix by generating uniformly distributed 
%random numbers from 0 to 1 and rescaling to [-range,range]
% INPUT: features, OUTPUT: scalar int (label number)
fanIn = params.numHid;
range = 1/sqrt(fanIn);
Wcat = -range + (2*range).*rand(params.numLabels,fanIn);
Wcat(:,end+1) = zeros(params.numLabels,1);
