
result_folder = '../results';
load([result_folder '/netFile.mat']); %load deep learning model net (fully trained)

% modify this section accordingly to obtain test image slice files (.png or .jpeg)
inputFolderTest = 'path-to-folder-containing-folders-with-test-image-data-files';
filePattern = fullfile(inputFolderTest);
totalData = dir2(filePattern);
listName = {totalData.name}';
checkNumberList = [];
N = length(listName);
for i = 1:N
checkNumberList{i} = char(listName(i,:));
end
checkNumberList = checkNumberList';

classNames = ["pancreas","nonpancreas"];
pixelLabelID = [1 0];

for totLIST = 1:length(checkNumberList)
    
close all;

imageNumberX = checkNumberList{totLIST};
dataDir = [inputFolderTest '\' imageNumberX];
imDir = fullfile(dataDir,'img');
imds = imageDatastore(imDir,'FileExtensions','.png');
classNames = ["pancreas","nonpancreas"];
pixelLabelID = [1 0];
pxDir = fullfile(dataDir,'gt');
pxds = pixelLabelDatastore(pxDir,classNames,pixelLabelID);

% if image and ground-truth slices are not stored in numerical order
% (depending on file name,i.e. 1,10,100 not 01,02...10,11,...100), then
% sort into numerical order
%{

ImgsX = fullfile(dataDir2,'img');
ImgsXGT = fullfile(dataDir2,'gt');
Imgs = dir2(ImgsX); ImgsGT = dir2(ImgsXGT);
CopyImgs = Imgs; CopyGT = ImgsGT;
NumImgs = size(Imgs,1);
tracked = 0;
for o = 1:NumImgs
     for s = 1:NumImgs
         imagename = Imgs(s).name;
         numImage = sscanf(imagename,'image_%d');
         if(numImage == o)
             CopyImgs(o) = Imgs(s);
             CopyGT(o) = ImgsGT (s);
             tracked = tracked + 1;
         end
     end  
end  

CopyImgsCell = cell(NumImgs,1);
CopyImgsCellGT = cell(NumImgs,1);
for t = 1:NumImgs 
    folderName = [CopyImgs(t).folder '\' CopyImgs(t).name];
    CopyImgsCell{t,1} = folderName;
    folderNameGT = [CopyGT(t).folder '\' CopyGT(t).name];
    CopyImgsCellGT{t,1} = folderNameGT;
end

imds.Files = CopyImgsCell;
imds = imageDatastore(CopyImgsCell,'FileExtensions','.png');
pxds = pixelLabelDatastore(CopyImgsCellGT,classNames,pixelLabelID);
%}

thirdSize = size(pxds2.Files,1);
imWidth = 'define'; imHeight = 'define';
predict = logical(zeros(imHeight,imWidth,thirdSize));
goldStandard = logical(zeros(imHeight,imWidth,thirdSize));
%}

for gs = 1:size(predict,3)
expectedResult = uint8(readimage(pxds2,gs));
G = zeros(size(expectedResult));
G(expectedResult==2)=0; G(expectedResult==1)=1;
G = logical(G);
goldStandard(:,:,gs) = G;
end

for t = 1:size(predict,3)   
I = readimage(imds2,(t));
C = semanticseg2(I, net);
D = uint8(double(C));
D1 = zeros(size(D));
D1(D==2)=0; D1(D==1)=1;
D1 = logical(D1);
%}

predict(:,:,t) = D1;
%figure;
%imshow(predict(:,:,t),[]);
end

%figure;
%isosurface(predict,0.1)

% extract largest volume (eliminate surrounding clutter)
labeledImage = bwlabeln(predict, 6);     
blobMeasurements = regionprops(labeledImage, predict, 'area');
allBlobAreas = [blobMeasurements.Area];
[sortedAreas, sortIndexes] = sort(allBlobAreas, 'descend');
biggestBlob = ismember(labeledImage, sortIndexes(1:1));
predict = biggestBlob > 0;
%}

[DC] = diceScoreX(logical(goldStandard),logical(predict));
DC = DC * 100

[jaccardIdx,~] = jaccard_coefficient(logical(goldStandard),logical(predict));
JI = jaccardIdx*100


figure;
p1 = isosurface(goldStandard,0.1);
p2 = patch(p1);
set(p2,'FaceColor','red','EdgeColor','none','FaceAlpha',0.3);
daspect([1,1,1])
view(3); 
camlight; lighting gouraud
p3 = isosurface(predict,0.1);
p4 = patch(p3);
set(p4,'FaceColor','green','EdgeColor','none','FaceAlpha',0.5);
title([imageNumberX ' DSC(%): ' num2str(DC)]);

resultFile = [dataDir '\dl_pancreas.mat'];
save(resultFile,'-v7.3','predict');
save(resultFile,'goldStandard','-append');
save(resultFile,'DC','-append');
save(resultFile,'JI','-append');

%}

end
