function [Sout] = DirLabelOrgVolFrac(Snew,inorganic,organic,varargin)
%% [Sout]=DirLabelOrgVolFrac(Snew,inorganic,organic)
% Calculates organic volume fraction
%
% If inorganic and organic are blank, NaCl and adipic acid are used
% respectively
%
% varargin{1} accepts 1 or 0, chooses to run or skip the "high OD
% correction" segment
%
% Need to run CarbonMaps.m first

%% OUTPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sout.VolFrac is a vector of individual particle volume fractions
% Sout.ThickMap is a map of inorganic and inorganic thicknesses as well as a volume fraction map
% Sout.MassMap is a map of masses calculated from the above thicknesses and the assumptions about density

%% To do list:
% 1. handle thick inorganic regions
% 2. Incorporate to DirLabelMapsStruct.m (which feeds the ParticleAnalysis2 app)

%% Define varibles from CarbonMaps
Mask = Snew.binmap;
LabelMat = Snew.LabelMat;

%% Find energies
% pre edge energy
[~,preidx] = min(abs(Snew.eVenergy - 278)); %find(Snew.eVenergy<283);
preval = Snew.eVenergy(preidx);
if preval > 283 || preval < 260
	disp('----Cant find C pre-edge (278eV)----');
end

% post edge energy
[~,postidx] = min(abs(Snew.eVenergy - 320));%find(Snew.eVenergy>310 & Snew.eVenergy<330); %length(Snew.eVenergy);
postval = Snew.eVenergy(postidx);
if postval < 310 || postval > 330
	disp('----Cant find C post-edge (320eV)----');
end

% sp2 absorption
[~,sp2idx] = min(abs(Snew.eVenergy - 285.4));
sp2val = Snew.eVenergy(sp2idx);
sp2flag = 1;
if sp2val < 284.5 || sp2val > 285.6
	disp('----Cant find sp2 transition energy (285.4eV)----');
	sp2flag = 0;
end

% cidx=find(Snew.eVenergy>288 & Snew.eVenergy<289);
% if isempty(cidx)
%     cidx=postidx;
% end

preim=Snew.spectr(:,:,preidx);
postim=Snew.spectr(:,:,postidx);

%% Determining and subtracting linear background gradient
try
	preim = FindingTotGradAngle(preim);
	postim = FindingTotGradAngle(postim);
catch
	disp('----linear background gradient not subtracted----');
end

% SNlimit = 3;
% 
% preim_noise = std(preim(Snew.mask==1));
% preim(preim < SNlimit.*preim_noise) = 0;
% 
% postim_noise = std(postim(Snew.mask==1));
% postim(postim < SNlimit.*postim_noise) = 0;


%% Input checking
if nargin == 1
    inorganic = 'NaCl';
    organic = 'adipic';
end

if isempty(varargin)
	highODcorrectionflag = 1;
elseif length(varargin) == 1
	highODcorrectionflag = varargin{1};
end

%% Getting mass absorption coefficients
[uorgpre,uorgpost,uinorgpre,uinorgpost]=PreToPostRatioVolFrac(inorganic,organic); %% get calculated cross sections in cm^2/g

%% Density of common compounds
inorglist =     {'(NH4)2SO4','NH4NO3','NaNO3','KNO3','Na2SO4','NaCl','KCl','Fe2O3','CaCO3','ZnO','Pb(NO3)2','Al2Si2O9H4'};
inorgdenslist = {1.77       ,1.72    ,2.26   ,2.11  ,2.66    ,2.16  ,1.98 ,5.24   ,2.71   ,5.61 ,4.53      ,2.60}; % g/cm^3

orglist =       {'adipic','glucose','oxalic','sucrose','tricarboxylic acid','pinonic acid','pinene'};
orgdenslist =   {1.36    ,1.54     ,1.9     ,1.59	  ,1.7				   ,1.1			  ,0.86}; % g/cm^3
orgMWlist =		{146.1412,180.156  ,90.03   ,34.2965  ,176.12			   ,184.235		  ,136.24};
orgCnumlist =	{6       ,6        ,2       ,12		  ,6				   ,10			  ,10}; %number of carbons in given organic

sootDens = 1.8; % g/cm^3
sootMW = 12.01;

%% Picking from above list based on fxn inputs
inorgDens=inorgdenslist{strcmp(inorglist,inorganic)}; %this picks the density coresponding with the inorganic chosen above

orgDens=orgdenslist{strcmp(orglist,organic)}; 
orgMW = orgMWlist{strcmp(orglist,organic)};

orgNc = orgCnumlist{strcmp(orglist,organic)};

%% Helpful substitution -- added 1/9/17
xin=uinorgpost./uinorgpre; % unitless
xorg=uorgpre./uorgpost;

%% Calculating organic thickness
% torg=(postim-xin.*preim)./(uorgpost.*orgDens+xin.*uorgpre.*orgDens); %
% ^^ old def before 1/9/2017 - note sign difference with the following:
torg = (postim-xin.*preim)./(uorgpost.*orgDens-xin.*uorgpre.*orgDens); % in cm
torg(torg<0) = 0; % no negative thicknesses

torg = torg .* (10^6/10^2); % convert to micrometers

%% Calculating inorganic thickness -- updated due to error 1/9/17
% figure,imagesc(torg),colorbar;
% tinorg=(preim-uorgpre.*((postim-xin.*preim)./(uorgpost+xin.*uorgpre)))./...
%     (uinorgpre.*inorgDens);
tinorg = (preim-xorg.*postim)./(uinorgpre.*inorgDens-xorg.*uinorgpost.*inorgDens);
tinorg(tinorg<0) = 0;

tinorg = tinorg .* (10^6/10^2); % convert to micrometers

%% Helpful values
% figure,imagesc(tinorg),colorbar;
% figure,imagesc(volFraction),colorbar
MatSiz=size(LabelMat);
XSiz=Snew.Xvalue/MatSiz(1); % in microns
YSiz=Snew.Yvalue/MatSiz(2);
xdat=[0:XSiz:Snew.Xvalue];
ydat=[0:YSiz:Snew.Yvalue];
pixelsize=mean([XSiz,YSiz]);

%% Correct for thick inorganic regions assuming thickness is that of a cube
ODlim = 1.5;
if highODcorrectionflag == 1
	if sum(preim(preim>ODlim))>0 % if the particle contains thick regions with OD>1.5
		for i=1:max(max(LabelMat)) % loop over each particle
			npix=length(preim(LabelMat==i & preim>ODlim)); %count pixels in ith particle that have OD>1.5
			if npix == 0
				continue
			end
			
			highodim = zeros(size(LabelMat));
			highodim(LabelMat == i) = 1;
			highodim(preim < ODlim) = 0;
			rowvec = sum(highodim,1);
			colvec = sum(highodim,2);
			zerocols = find(rowvec==0);
			zerorows = find(colvec==0);
			
			highodim(zerorows,:) = [];
			highodim(:,zerocols) = [];
			
			[highod_ysize , highod_xsize] = size(highodim);
			
			%this chooses the smallest value.  this will better approximate
			%things like a rectangle, where the height is most likely equal to
			%the shorter side.  sqrt(npix) is still included because for
			%sprawling, fractal regions that are large but contain few pixels,
			%using x or y size would overestimate these regions.
			pixel_thickness = min([highod_ysize, highod_xsize, sqrt(npix)]);
			% 		pixel_thickness = sqrt(npix);
			
			thickness=pixel_thickness.*pixelsize; % calculate inorganic the thickness based on that of a cube (works for big NaCl inclusions) -- thickness in micrometers
			tinorg(LabelMat==i & preim>ODlim)=thickness; % for the ith particle, replace OD>1.5 thicknesses with geometric correction
		end
	end
end
%% Correct for soot containing particles (per-pixel correction)
tsoot=zeros(size(torg));
if sp2flag == 1
	if ~isempty(sp2idx)
		tsoot = (Snew.sp2 .* Snew.BinCompMap{3})  .*  (orgNc .* torg .* orgDens ./ orgMW)  .*  (sootMW ./ sootDens); % in micrometers -- the orgDens and sootDens are in g/cm^3 but they cancel each other out
		torg(Snew.BinCompMap{3}==1) = (1 - Snew.sp2(Snew.BinCompMap{3}==1)) .* torg(Snew.BinCompMap{3}==1);
	end
end

%% Calculate Organic Volume Fraction
volFraction=torg./(torg+tinorg+tsoot);
volFraction(Mask==0)=0;

%% Integrate volume fractions for individual particles
volFrac=zeros(max(max(LabelMat)),1);
for i=1:max(max(LabelMat)) % loop over particles
    sumOrgThick=nansum(torg(LabelMat==i));
    sumInorgThick=nansum(tinorg(LabelMat==i));
	sumSootThick = nansum(tsoot(LabelMat==i));
    volFrac(i)=sumOrgThick./(sumOrgThick+sumInorgThick+sumSootThick);
end

%% Do figures
% figure('Name',Snew.particle,'NumberTitle','off','Position',[1,1,715,869]);
% subplot(2,2,1),imagesc(xdat,ydat,torg),colorbar, 
% axis image, 
% title('organic thickness (m)'), 
% xlabel('X (\mum)');
% ylabel('Y (\mum)'); 
% subplot(2,2,2),imagesc(xdat,ydat,tinorg),colorbar,axis image,
% title('inorganic thickness (m)'), 
% xlabel('X (\mum)');
% ylabel('Y (\mum)');
% subplot(2,2,3),imagesc(xdat,ydat,tsoot),colorbar,
% axis image,
% title('soot thickness'),
% xlabel('X (\mum)');
% ylabel('Y (\mum)');
% subplot(2,2,4),imagesc(xdat,ydat,volFraction),colorbar,
% axis image,
% title('organic volume fraction'),
% xlabel('X (\mum)');
% ylabel('Y (\mum)');
% 
% figure, hist(VolFrac), 
% title('Organic Volume Fraction'),
% xlabel('volume fraction'),
% ylabel('#');
% export_fig([Snew.particle,'OVFa'],'-png');% 

%% Prepare outputs
Snew.VolFrac=volFrac;
ThickMap(:,:,1) = torg;
ThickMap(:,:,2) = tinorg;
ThickMap(:,:,3) = tsoot;
ThickMap(:,:,4) = volFraction;

MassMap.org = (torg .* XSiz .* YSiz) .* orgDens .* (10^3 ./ 10^2)^3 ; % in micrograms
MassMap.inorg = (tinorg .* XSiz .* YSiz) .* inorgDens .* (10^3 ./ 10^2)^3 ; % in micrograms
MassMap.soot = (tsoot .* XSiz .* YSiz) .* sootDens .* (10^3 ./ 10^2)^3 ; % in micrograms

Snew.ThickMap = ThickMap;
Snew.MassMap = MassMap;
Snew.VolFrac = volFrac;
Snew.OVFassumedorg = organic;
Snew.OVFassumedinorg = inorganic;

Sout=Snew;



end


