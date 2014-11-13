% Type is train, valid, or eval
function [ imageNames ] = ReadFoldImageNames( dataset,fold, type )

    if (~strcmp(type,'train') && ~strcmp(type,'valid') && ~strcmp(type,'eval'))
        error('Invalid type. Only train, valid and eval accepted.')
    end
    
    filename = ['/esat/sadr/amartino/RNN/data/' dataset '/' type 'List' num2str(fold) '.txt'];
    if ~exist(filename,'file')
        imageNames=[];
        return;
    end
    delimiter = '';
    formatSpec = '%s%[^\n\r]';
    fileID = fopen(filename,'r');
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter,  'ReturnOnError', false);
    fclose(fileID);
    imageNames = [dataArray{:,1:end-1}];
   

end

