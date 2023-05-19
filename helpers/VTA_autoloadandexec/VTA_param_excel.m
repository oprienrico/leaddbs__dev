function [] = VTA_param_excel(handles)
% stimulate_Callback calls this function if
% the user is using a csv file for params

% What's different here compared to ea_stimparams 
% is that we're going to construct our own S rather
% than read it from the GUI, and then iteratively call the stimulate
% functions from stimulate_Callback over the Ss we constructed

elstruct = getappdata(handles.stimfig,'elstruct');
resultfig = getappdata(handles.stimfig,'resultfig');
options = getappdata(handles.stimfig,'options');
% refresh prefs:
options.prefs = ea_prefs;
setappdata(resultfig,'options',options);
setappdata(handles.stimfig,'options',options);

% Need to be careful with string security buffers here?
filename = get(handles.param_filename_box,'String');

file = array2table(zeros(1));
try
    file = readtable(filename);
catch
    disp(['Error; try checking file validity: ',filename]);
end

options = getappdata(resultfig,'options'); % selected atlas could have refreshed.
options.orignative = options.native;

for i = 1:height(file)

    % Constructs an S (stimulation) struct based on the current row in the csv
    S = S_list_cons(file,i);

    ea_savestimulation(S,options)

    switch S.model
    case 'Dembek 2017'
        label = 'dembek';
    case 'Fastfield (Baniasadi 2020)'
        label = 'fastfield';
    case 'Kuncel 2008'
        label = 'kuncel';
    case 'Maedler 2012'
        label = 'maedler';
    case 'SimBio/FieldTrip (see Horn 2017)'
        label = 'horn';
    case 'OSS-DBS (Butenko 2020)'
        label = 'butenko';
    end

    fxn_name = ['ea_genvat_' label];
    ea_genvat=eval(['@' fxn_name]);

    for el=1:length(elstruct)
        % Load stim coordinates
        if options.native % Reload native space coordinates
            coords = ea_load_reconstruction(options);
        else
            coords = elstruct(el).coords_mm;
        end
    
        % For OSS-DBS, side iteration is within the genvat function
        if strcmp(S.model, 'OSS-DBS (Butenko 2020)')
            % Set stimSetMode flag to options
            % (avoid additional parameter or setting appdata, to make it scriptable)
            if handles.addStimSet.Value
                options.stimSetMode = 1;
            else
                options.stimSetMode = 0;
            end
            if options.prefs.machine.vatsettings.butenko_calcAxonActivation
                feval(ea_genvat,S,options,handles.stimfig);
                ea_busyaction('off',handles.stimfig,'stim');
                return;
            else
                [~, stimparams] = feval(ea_genvat,S,options,handles.stimfig);
                flix=1;
            end
        % If not OSS-DBS
        else
            stimparams = struct();
            for iside=1:length(options.sides)
                side=options.sides(iside);
                [vatfv, vatvolume]=feval(ea_genvat,coords,S,side,options,S.label,handles.stimfig);
                stimparams(1,side).VAT(el).VAT = vatfv;
                stimparams(1,side).volume = vatvolume;
                flix=1;
            end
        end

    end
    
    % Adapted from ea_stimparams
    options.native=options.orignative;
    PL=getappdata(resultfig,'PL');
    for group=1:length(PL)
        ea_deletePL(PL(group));
    end
    clear PL
    
    for group=flix
        setappdata(resultfig,'stimparams',stimparams(group,:));
        setappdata(resultfig,'curS',S(group));
    
        if ~exist('hmchanged','var')
            hmchanged=1;
        end
        ea_calc_vatstats(resultfig,options,hmchanged);
    
        %copyfile([options.root,options.patientname,filesep,'ea_stats.mat'],[options.root,options.patientname,filesep,'ea_stats_group_',num2str(group),'.mat']);
        try
            copyfile([options.root,options.patientname,filesep,'ea_pm.nii'],[options.root,options.patientname,filesep,'ea_pm_group_',num2str(group),'.nii']);
        end
        try
            PL(group)=getappdata(resultfig,'PL');
        catch
            keyboard
        end
    end
    % Don't update GUI every iteration
    %setappdata(resultfig,'PL',PL);
    
    % save stimulation every time
    ea_savestimulation(S,options)
end

