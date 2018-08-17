function multihdrsplit(hdr)

filestream = fopen(hdr, 'r');    %% Open file
numregions = [];
alphastr = 'abcdefghijklmnopqrstuvwxyz'; %this allows me to append a letter instead of a number
paxiscnt = 0;
pregioncnt = 1;
qaxiscnt = 0;
qregioncnt = 1;
poslinecnt = 0;
posregioncnt = 1;
linecnt = 1; %this counts lines of text common between all hdr files
topstr = cell(4,1); %preallocating a cell to stop a warning below even though this is probably uncessary
while feof(filestream) == 0
	line=fgets(filestream);
    pidx = strfind(line,'PAxis');
    qidx = strfind(line,'QAxis');
    posidx = strfind(line,'CentreXPos');
    
    if isempty(numregions)
        multflag = strfind(line,'	Regions = (');
        if ~isempty(multflag)
            multflag2 = strfind(line,',');
            numregions = str2double(line(multflag+12:multflag2-1));
            hdrcell = cell(1,numregions);
            for i = 1:length(topstr)
                for k = 1:numregions;
                    hdrcell{i,k} = topstr{i};
                end
            end
        end
    end
    
    if ~isempty(pidx)
        hdrcell{linecnt+paxiscnt,pregioncnt} = line;
        while isempty(strfind(line,'};'))
            line = fgets(filestream);
            paxiscnt = paxiscnt+1;
            hdrcell{linecnt+paxiscnt,pregioncnt} = line;
        end
        paxiscnt = paxiscnt + 1;
        pregioncnt = pregioncnt + 1; %this sets up the next loop to use the next column in hdrcell
        fgets(filestream); %skipping a blank line
        
    elseif ~isempty(qidx)
        hdrcell{linecnt+paxiscnt+qaxiscnt,qregioncnt} = line;
        while isempty(strfind(line,'};'))
            line = fgets(filestream);
            qaxiscnt = qaxiscnt+1;
            hdrcell{linecnt+paxiscnt+qaxiscnt,qregioncnt} = line;
        end
        qaxiscnt = 0;
        paxiscnt = 0; %this resets the line count for paxis stuff for the next region's paxis info
        qregioncnt = qregioncnt + 1;
        fgets(filestream); %skipping two lines to skip unecessary lines
        fgets(filestream);
        
    elseif ~isempty(posidx)
        hdrcell{linecnt+poslinecnt,posregioncnt} = line;
        posregioncnt = posregioncnt + 1;
        
    elseif isempty(numregions)
        topstr{linecnt} = line;
        linecnt = linecnt+1;
        
    elseif ~isempty(numregions)
        if any(multflag)
            regionline = sprintf('%s',line(multflag:multflag+11),'1',line(multflag2));
            linecnt = size(hdrcell,1) + 1; %size is used instead of length for the couple lines where it is smaller than the number of regions
            for i = 1:numregions
                hdrcell{linecnt,i} = regionline;
            end
            linecnt = linecnt+1;
            multflag = 0;
            multflag2 = 0;
            continue
        end
        linecnt = size(hdrcell,1) + 1; %size is used instead of length for the couple lines where it is smaller than the number of regions
        for i = 1:numregions
            hdrcell{linecnt,i} = line;
        end
        linecnt = linecnt+1;
    end
end

for i = 1:numregions
    newhdr = sprintf('%s',hdr(1:end-4),alphastr(i),'.hdr');
    FID = fopen(newhdr,'w');
    fprintf(FID,'%s',hdrcell{:,i});
    fclose(FID);
end

fclose(filestream);

end