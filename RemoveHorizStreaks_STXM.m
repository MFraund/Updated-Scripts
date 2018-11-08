function [ OutputStruct ] = RemoveHorizStreaks_STXM( InputStruct )
%REMOVEHORIZSTREAKS_STXM Summary of this function goes here
%   Detailed explanation goes here


%% Redefining inputs
S = InputStruct;

%% Determining which rows are mostly outliers
allbadrowidx = [];
for i = 1:size(S.spectr,3)
	currim = S.spectr(:,:,i);
	sumim = sum(currim,2);
	
	% Rows which exceed 1.5 x the distance between the 75%ile and the 25%ile are deemed outliers and set to 0
	cleanedsum = removeoutlier_IQRtest(sumim);
	badrowidx = find(cleanedsum == 0);
	allbadrowidx = [allbadrowidx ; badrowidx];
end

% Making sure bad rows are dealt with for all images/energies
allbadrowidx = sort(unique(allbadrowidx));

%% Setting outlier rows to the median value
for j = 1:size(S.spectr,3)
	currim2 = S.spectr(:,:,j);
	currim2(allbadrowidx,:) = median(median(currim2));
	currim2 = medfilt2(currim2);
	S.spectr(:,:,j) = currim2;	
end

%% Defining Outputs
OutputStruct = S;

end