function MergingRawSTXMData()

f = figure(...
	'Units','normalized',...
	'Position',[0.1,0.1,0.6,0.6],...
	'Name','Merging STXM Data');

hdatalist = uicontrol(...
	'Style','listbox',...
	'Max',1,...
	'Min',0,...
	'Units','normalized',...
	'Callback',{@hdatalist_callback},...
	'Position',[0.01,0.07,0.34,0.8]);

hfilelist = uicontrol(...
	'Style','listbox',...
	'Max',100,...
	'Min',0,...
	'Units','normalized',...
	'Position',[0.36,0.07,0.30,0.8]);

hmergelist = uicontrol(...
	'Style','listbox',...
	'Max',100,...
	'Min',0,...
	'Units','normalized',...
	'Position',[0.67,0.07,0.30,0.8]);

hload = uicontrol(...
	'Style','pushbutton',...
	'String','Load STXM Data',...
	'Units','normalized',...
	'Tag','Load',...
	'Position',[0.01,0.88,0.12,0.053],...
	'Callback',{@hload_callback});

hmove = uicontrol(...
	'Style','pushbutton',...
	'String','Choose Files',...
	'Units','normalized',...
	'Enable','off',...
	'Position',[0.45,0.88,0.12,0.053],...
	'Callback',{@hmove_callback});

hmerge = uicontrol(...
	'Style','pushbutton',...
	'String','Merge Lists',...
	'Units','normalized',...
	'Tag','Load',...
	'Enable','off',...
	'Position',[0.85,0.88,0.12,0.053],...
	'Callback',{@hmerge_callback});

hmerge_info = uicontrol(...
	'Style','text',...
	'String','This list must have energies in ascending order',...
	'Units','normalized',...
	'Position',[0.68,0.88,0.17,0.06]);

	global filedirs
	global premerge_ximnames
	global premerge_ximfiles
	global premerge_ximenergynames
	global premerge_energies
	premerge_energies = [];
	premerge_ximnames = [];
	premerge_ximfiles = [];
	premerge_ximenergynames = [];
	%global folders



	function hload_callback(loadObject,~)
		filedirs = uipickfiles; %calls up gui to pick multiple directories
		numdirs = length(filedirs);
		displaydirs = cell(1,numdirs);
		for i = 1:numdirs; %looping through each selected directory
			[~,folders{i},~] = fileparts(filedirs{i}); %only picking the foldernames for brevity
			
			
			
			cd(filedirs{i}); %moving to each directory
			currdir = dir;
			currfolder = pwd;
			cnt = 1;
			for j = 1:length(currdir)
				hdrflag = strfind(currdir(j).name,'.hdr');
				ximflag = strfind(currdir(j).name,'.xim');
				if ~isempty(hdrflag)
					hdrloc = j;
					hdrfiles{i}{cnt,1} = [currfolder, '\', currdir(j).name];
				elseif ~isempty(ximflag)
					ximnames{i}{cnt,1} = currdir(j).name(1:ximflag-1);
					
					ximfiles{i}{cnt,1} = [currfolder, '\', currdir(j).name];
					cnt = cnt + 1;
				end
			end
			[evenergy{i},~,~,~,~]=ReadHdrMulti(currdir(hdrloc).name);
			elestruct = energytest(evenergy{i});
			
			elelist = {'C','N','O','Ca','K','S'};
			elestring = [];
			for k = 1:length(elelist)
				if elestruct.elements.(elelist{k}) == 1
					elestring = [elestring, elelist{k}];
				end
			end
			
			displaydirs{i} = [folders{i}, '  |  ', elestring];
		end
		set(hdatalist,'String',displaydirs);
		set(hmove,'Enable','on');
		userdatastruct = struct('folders',folders,'evenergy',evenergy,'ximnames',ximnames,'ximfiles',ximfiles,'hdrfiles',hdrfiles);
		set(loadObject,'UserData',userdatastruct);
		
		hdatalist_callback()
	end

	function hdatalist_callback(~,~)
		loadstruct = get(hload,'UserData');
		loadval = get(hdatalist,'Value');
		
		ximnamescell = loadstruct(loadval).ximnames;
		%ximnamescell = bigximnamescell{loadval};
		
		energyvec = loadstruct(loadval).evenergy;
		%energyvec = bigenergycell{loadval};
		energycell = mat2cell(energyvec,ones(numel(energyvec),1),1);
		energycell_str = cellfun(@num2str,energycell,'UniformOutput',0);
		
		cellspacing = cell(size(energycell_str));
		cellspacing(:) = {'  |  '};
		energy_xim_cell = cellfun(@horzcat,ximnamescell,cellspacing,energycell_str,'UniformOutput',0);
		
		set(hfilelist,'String',energy_xim_cell);
		
		
		
		
		
	end

	function hmove_callback(~,~)
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		folderval = get(hdatalist,'Value');
		filevals = get(hfilelist,'Value');
		energy_xim_cell = get(hfilelist,'String');
		
		loadstruct = get(hload,'UserData');
		ximnamescell = loadstruct(folderval).ximnames;
		ximfilescell = loadstruct(folderval).ximfiles;
		energyvec = loadstruct(folderval).evenergy;
		premerge_energies = [premerge_energies , energyvec(filevals)'];
		premerge_ximnames = [premerge_ximnames ; ximnamescell(filevals)];
		premerge_ximfiles = [premerge_ximfiles ; ximfilescell(filevals)];
		premerge_ximenergynames = [premerge_ximenergynames ; energy_xim_cell(filevals)];
		set(hmergelist,'String',premerge_ximenergynames);
		set(hfilelist,'Value',1);
		set(hmerge,'Enable','on');
	end


	function hmerge_callback(~,~)
		selectedvals = get(hdatalist,'Value');
		loadstruct = get(hload,'UserData');
% 		folders = hload.folders;
		%cd(filedirs{selectedvals(1)});
		%cd('..');
		varcheck = premerge_ximfiles;
		cnt = 1;
		for i = 1:length(premerge_ximfiles)
			
			[~,currfolder] = fileparts(fileparts(premerge_ximfiles{i}));
			if i > 1
				if strcmp(fileparts(premerge_ximfiles{i}),fileparts(premerge_ximfiles{i-1})) == 1;
					continue
				end
			end
			cd(fileparts(premerge_ximfiles{i}));
			flag_532 = strfind(currfolder,'532_');
			flag_cls = strfind(currfolder,'A');
			if ~isempty(flag_532)
				filedate_startidx = flag_532+4;
			elseif ~isempty(flag_cls)
				filedate_startidx = flag_cls+1;
			else
				continue
			end
			
			if cnt == 1
				first_foldername = currfolder(filedate_startidx:filedate_startidx+8);
			end
			foldershortnames{cnt} = currfolder(filedate_startidx+6:filedate_startidx+8);
			cnt = cnt + 1;
		end
		
		
		mergename = ['Merged_',first_foldername];
		for j = 2:length(foldershortnames)
			mergename = [mergename,'_',foldershortnames{j}];
		end
		
		cd('..');
		currfolder = pwd;
		mkdir(mergename)
		
		mergedir = [currfolder,'\',mergename];
		
		for k = 1:length(premerge_ximfiles)
			newximname = [premerge_ximnames{k} , '_m' , num2str(k)];
			newximfile = [mergedir, '\', newximname, '.xim'];
			copyfile(premerge_ximfiles{k},newximfile);
			%cd(filedirs{selectedvals(k)});
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Left Off
			%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Here
		end
		newhdrfile = [mergedir,'\',mergename,'.hdr'];
		%copyfile(loadstruct(1).hdrfiles,newhdrfile);
		fin = fopen(loadstruct(1).hdrfiles{1},'r');
		fout = fopen(newhdrfile,'w');
		cnt = 1;
		energyflag = 0;
		energystring = [];
		while feof(fin) == 0
			line = fgets(fin);
			energypos = strfind(line,'StackAxis');
						
			if energyflag == 1
				energystring = sprintf('\t\t%s%s','Points = (', num2str(length(premerge_energies)));
				for q = 1:length(premerge_energies)
					energystring = [energystring, ', ', num2str(premerge_energies(q))];
				end
				energystring = sprintf('%s%s',energystring , ');');
				line = energystring;
				energyflag = 0;
			end
			
			if ~isempty(energypos)
				energyflag = 1;
			end
			
			fprintf(fout,'%s',line);
		end
		fclose(fin);
		fclose(fout);
		
		close(f);
	end






end