function [ ArrayNoOutliers ] = removeoutlier_IQRtest( ArrayWithOutliers )
%REMOVEOUTLIER_IQRTEST Removes large positive outliers from a set of
%positive nonzero data.
%   Removes outliers from data using the inter quartile range test (3rd
%   quartile max + 1.5*IQR).  This is meant for positive, nonzero data.
%   Zeros are excluded from calculations

ar = ArrayWithOutliers;

outlierflag = 1;
upperq3 = prctile(ar(ar~=0),75);
iqr = upperq3 - prctile(ar(ar~=0),25);

%this removes a lot of pixels that are huge and leaves the fine tuning for the loop.
% Because this works with only positive, nonzero data, the iqr is only ever
% going to shrink with the iterations below.  everything that is bigger
% than upperq3+1.5*iqr is always going to be bigger.
ar(ar>upperq3+1.5.*iqr) = 0; 
while outlierflag == 1;
    upperq3 = prctile(ar(ar~=0),75);
    iqr = upperq3 - prctile(ar(ar~=0),25);
    testoutlier = max(max(ar));
    if testoutlier > upperq3 + iqr.*1.5
        ar(ar == testoutlier) = 0;
    else
        outlierflag = 0;
    end
end

ArrayNoOutliers = ar;
end

