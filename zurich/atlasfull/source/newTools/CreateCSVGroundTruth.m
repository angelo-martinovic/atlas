function CreateCSVGroundTruth (labelID)

    dataset = 'eTrims';
    dataLocation = '/usr/data/amartino/gould/testEtrimsJournal/';
    nClasses = 8;

    objectAnnoLocation = '/usr/data/amartino/Facades/etrims-db_v1/annotations-object/08_etrims-ds/';
    
    % Load all image names
    trainImageNames = ReadFoldImageNames( dataset,1, 'train' );
    validImageNames = ReadFoldImageNames( dataset,1, 'valid' );
    testImageNames = ReadFoldImageNames( dataset,1, 'eval' );

    imageNames = [trainImageNames; validImageNames; testImageNames];
    origImageNames = strcat(dataLocation,imageNames);

    groundTruthFilenames = strcat(origImageNames,'.txt');
    imageFilenames = strcat(imageNames,'.jpg');
    
    objectAnnoImageNames = strcat(objectAnnoLocation,imageNames);
    objectAnnoFilenames = strcat(objectAnnoImageNames,'.png');

    fid = fopen('out.txt','w+');

    totalObjectsFound = 0;
    for i=1:length(groundTruthFilenames)
      fprintf('.');
      labels = dlmread(groundTruthFilenames{i});
      homographyFilename = strcat(groundTruthFilenames{i}(1:end-4),'rect.dat');
      homography = load(homographyFilename);
      
      objectAnno = imread(objectAnnoFilenames{i});
      
      invHomography = inv(reshape(homography,3,3));
      invHomography = invHomography(:);
      
      objectAnnoRect = rewarp(labels,single(objectAnno),invHomography,'linear');
      
      objectAnno = uint8(objectAnnoRect);
      clear objectAnnoRect;
      
%       figure(1),imagesc(labels);
      for j=1:max(objectAnno(:))
          objectMask = (objectAnno == j);
          
          labelMask = labels(objectMask);
          classes = zeros(1,nClasses);
          for c=1:nClasses
              classes(c)=sum(sum(labelMask==c));
          end
          [val,pos] = max(classes);
          if pos==labelID
              totalObjectsFound = totalObjectsFound+1;
              [r, c] = find(objectAnno == j);
              fprintf(fid,'%s;%d;%d;%d;%d;1\n',imageFilenames{i},min(c),min(r),max(c),max(r));
%               rectangle('Position',[min(c),min(r),max(c)-min(c),max(r)-min(r)],'edgecolor','w');
          end
      end
        
    end
    fclose(fid);
    disp(totalObjectsFound);


end