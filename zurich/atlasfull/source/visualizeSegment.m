function canvas = visualizeSegment(imgData,imgTree,seg)

    height = size(imgData.img,1);
    width = size(imgData.img,2);

    canvas = zeros(height,width);
    canvas(imgData.segs2==seg) = 1;
    
    if (imgTree.kids(seg,1)>0)
        canvas = canvas + visualizeSegment(imgData,imgTree,imgTree.kids(seg,1));
    end
    if (imgTree.kids(seg,2)>0)
        canvas = canvas + visualizeSegment(imgData,imgTree,imgTree.kids(seg,2));
    end
    %imagesc(canvas);
end