%[totalmfrac] = mfractions(ParticlesOverview)
%
%Extracts mass fractions of soot, inorganics, and organics from the
%"ParticlesOverview structure into
%
%input
%-----
%ParticlesOverview
%ParticlesOverview.Particles.Numparticles
%ParticlesOverview.Particles.CompMfracSoot
%ParticlesOverview.Particles.CompMfracInorg
%ParticlesOverview.Particles.CompMfracOrg
%
%output
%------
%totalmfrac
%totalmfrac.soot
%totalmfrac.inorg
%totalmfrac.org
%
%This is modified to work with making_gui where the data structure is
%slightly different than that of MixStateStats
%

function [totalmfrac] = extractingmfracGUI(Dataset)

totalmfrac = struct('soot',0,'inorg',0,'org',0);
totalnumberparticles = 0;
names = fieldnames(Dataset);
lstruc = length(Dataset);
for i = 1:lstruc
    if strfind(names{i},'FOV');
        fldnames2 = fieldnames(Dataset.(names{i}));
        lfldnames = length(fldnames2);
        for j = 1:lfldnames
            if isfield(Dataset.(names{i}).(fldnames2{j}),'Particles') == 0
                continue
            else
                totalnumberparticles = totalnumberparticles + Dataset(names{i}).(fldnames2{j}).Particles.Numparticles;
                totalmfrac.soot = totalmfrac.soot + nansum(Dataset(names{i}).(fldnames2{j}).Particles.CompMfracSoot);
                totalmfrac.inorg = totalmfrac.inorg + nansum(Dataset(names{i}).(fldnames2{j}).Particles.CompMfracInorg);
                totalmfrac.org = totalmfrac.org + nansum(Dataset(names{i}).(fldnames2{j}).Particles.CompMfracOrg);
            end
        end
    else
        continue
    end
end
totalmfrac.soot = totalmfrac.soot ./totalnumberparticles;
totalmfrac.inorg = totalmfrac.inorg ./totalnumberparticles;
totalmfrac.org = totalmfrac.org ./totalnumberparticles;
end