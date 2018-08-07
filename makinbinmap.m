function Snew = makinbinmap(Snew)

%this is only used if a FOV is analyzed but DOESNT have carbon data (rare
%for us).  If carbon data is present, this is overwritten

meanim=mean(Snew.spectr,3);
meanim(meanim>0.2)=0.2;
GrayImage=mat2gray(meanim); %% Turn into a greyscale with vals [0 1]
% GrayImage=imadjust(GrayImage,[0 1],[0 1],0.52); %% increase contrast
Thresh=graythresh(GrayImage); %% Otsu thresholding
binmap=im2bw(GrayImage,Thresh); %% Give binary image
% binmap = bwareaopen(binmap,3);
binmap=medfilt2(binmap);

LabelMat=bwlabel(binmap,8);

Snew.binmap = binmap;
Snew.LabelMat = LabelMat;
end