% getGridIndex  Returns the index of the adjacent cell in the grid in the given
% direction. 
%
%   index = getGridIndex(baseIndex, direction, numX, numY)
%
%   baseIndex is the index of the original cell.
%   direction is either 'left', 'right', 'top', or 'bottom'.
%   numX and numY define the number of horizontal and vertical grid elements.
function index = getGridIndex(baseIndex,direction,numX,numY)
index = 0;
if strcmp(direction,'left')
    if mod(baseIndex,numX)==1
        return;
    else
        index = baseIndex-1;
    end
elseif strcmp(direction,'right')
    if mod(baseIndex,numX)==0
        return;
    else
        index = baseIndex+1;
    end
elseif strcmp(direction,'top')
    if baseIndex<=numX
        return;
    else
        index = baseIndex-numX;
    end
elseif strcmp(direction,'bottom')
    if baseIndex>(numY-1)*numX
        return;
    else
        index = baseIndex+numX;
    end
else
    error('No such direction');
end