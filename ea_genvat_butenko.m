function varargout = ea_genvat_butenko(varargin)
% Wrapper for OSS-DBS for VTA calculation

if nargin==2
    S=varargin{1};
    options=varargin{2};
elseif nargin==3
    S=varargin{1};
    options=varargin{2};
    hFigure=varargin{3};
elseif nargin==1 && ischar(varargin{1}) % return name of method.
    varargout{1} = 'OSS-DBS (Butenko 2020)';
    varargout{2} = true; % Support directed lead
    return
end

% Check OSS-DBS installation, set env
if ~options.prefs.machine.vatsettings.oss_dbs.installed
    ea_checkOSSDBSInstall;
else
    binPath = getenv('PATH'); % Current PATH
    pythonPath = options.prefs.env.pythonPath;
    if isunix
        setenv('PATH', [pythonPath, ':', binPath]);
        pythonBinName = 'python3';
    else
        setenv('PATH', [pythonPath, ';', binPath]);
        pythonBinName = 'python';
    end
end

% docker image name
if ispc || ismac
    dockerImage = 'ningfei/oss-dbs';
else % Linux
    dockerImage = 'custom_oss-dbs';
end

% Double check if lead is supported by OSS-DBS.
if ~ismember(options.elmodel, ea_ossdbs_elmodel)
    ea_error([options.elmodel, 'is not supported by OSS-DBS yet!'], 'Error', dbstack)
end

% Set output path
subPrefix = ['sub-', options.subj.subjDir, '_desc-'];
outputDir = [options.subj.stimDir, filesep, ea_nt(options.native), S.label];
outputBasePath = [outputDir, filesep, 'sub-', options.subj.subjDir, '_sim-'];
ea_mkdir(outputDir);
if options.native
    templateOutputDir = [options.subj.stimDir, filesep, ea_nt(0), S.label];
    ea_mkdir(templateOutputDir);
    templateOutputBasePath = [templateOutputDir, filesep, 'sub-', options.subj.subjDir, '_sim-'];
end

%% Set MRI_data_name
% Segment MRI
segmaskName = 'segmask.nii';
if options.native
    anchorImage = options.subj.preopAnat.(options.subj.AnchorModality).coreg;
    [anchorImageDir, anchorImageName] = fileparts(anchorImage);
    anchorImageDir = [anchorImageDir, filesep];
    anchorImageName = [anchorImageName, '.nii'];

    c1File = setBIDSEntity(anchorImage, 'label', 'GM', 'mod', options.subj.AnchorModality, 'suffix', 'mask');
    c2File = setBIDSEntity(anchorImage, 'label', 'WM', 'mod', options.subj.AnchorModality, 'suffix', 'mask');
    c3File = setBIDSEntity(anchorImage, 'label', 'CSF', 'mod', options.subj.AnchorModality, 'suffix', 'mask');
    if ~isfile(c1File) || ~isfile(c2File) || ~isfile(c3File)
        ea_newseg(anchorImage, 0, 1);
        movefile([anchorImageDir, 'c1', anchorImageName], c1File);
        movefile([anchorImageDir, 'c2', anchorImageName], c2File);
        movefile([anchorImageDir, 'c3', anchorImageName], c3File);
    end

    segMaskPath = setBIDSEntity(anchorImage, 'label', 'C123', 'mod', options.subj.AnchorModality, 'suffix', 'mask');
else
    c1File = [ea_space, 'c1mask.nii'];
    c2File = [ea_space, 'c2mask.nii'];
    c3File = [ea_space, 'c3mask.nii'];
    if ~isfile(c1File) || ~isfile(c2File) || ~isfile(c3File)
        ea_newseg(fullfile(ea_space, [options.primarytemplate, '.nii']), 0, 1);
        movefile([ea_space, 'c1', options.primarytemplate, 'nii'], c1File);
        movefile([ea_space, 'c2', options.primarytemplate, 'nii'], c2File);
        movefile([ea_space, 'c3', options.primarytemplate, 'nii'], c3File);
    end

    segMaskPath = [ea_space, segmaskName];
end

if ~isfile(segMaskPath)
    % Binarize segmentations
    c1 = ea_load_nii(c1File);
    c2 = ea_load_nii(c2File);
    c3 = ea_load_nii(c3File);
    c1.img = c1.img>0.5;
    c2.img = c2.img>0.5;
    c3.img = c3.img>0.5;

    % Fuse segmentations by voting in the order  CSF -> WM -> GM
    c2.img(c3.img) = 0;
    c1.img(c2.img | c3.img) = 0;
    c1.img = c1.img + c2.img*2 + c3.img*3;
    c1.fname = segMaskPath;
    c1.dt = [2 0]; % unit8 according to spm_type
    c1.descrip = 'Tissue 1 + 2 + 3';
    c1.pinfo(1:2) = [1,0]; % uint8 is enough for output values, no need for scaling
    ea_write_nii(c1);
end

%% Set patient folder
settings.Patient_folder = options.subj.subjDir;

%% Set native/MNI flag
settings.Estimate_In_Template = options.prefs.machine.vatsettings.estimateInTemplate;

%% Set MRI path
% Put the MRI file in stimulation folder
copyfile(segMaskPath, [outputDir, filesep, segmaskName]);
settings.MRI_data_name = segmaskName;

%% Check tensor data
tensorName = options.prefs.machine.vatsettings.butenko_tensorFileName;
scalingMethod = options.prefs.machine.vatsettings.butenko_tensorScalingMethod;
scaledTensorName = strrep(tensorName, '.nii', ['_', scalingMethod, '.nii']);

nativeTensor = [options.subj.coregDir, filesep, 'dwi', filesep, subPrefix, tensorName];
nativeTensorScaled = [options.subj.coregDir, filesep, 'dwi', filesep, subPrefix, scaledTensorName];
templateTensor = [ea_space, filesep, tensorName];
templateTensorScaled = [ea_space, filesep, scaledTensorName];
tensorData = [outputDir, filesep, scaledTensorName]; % Final tensor data input for OSS-DBS

% Set to empty by default
settings.DTI_data_name = '';

if options.prefs.machine.vatsettings.butenko_useTensorData
    if isfile(tensorData)
        % Scaled tensor data found in stimulation folder
        settings.DTI_data_name = scaledTensorName;

    elseif ~options.native && isfile(templateTensorScaled)
        % MNI mode, scaled tensor data found in MNI space folder
        copyfile(templateTensorScaled, outputDir);
        settings.DTI_data_name = scaledTensorName;

    elseif options.native && isfile(nativeTensorScaled)
        % native mode, scaled tensor data found in patient folder
        copyfile(nativeTensorScaled, tensorData);
        settings.DTI_data_name = scaledTensorName;

    else
        if ~options.native
            % MNI mode, tensor data found
            if isfile(templateTensor)
                tensorDir = ea_space;
                tensorPrefix = '';
            end
        else
            % native mode, tensor data not found, warp template tensor data
            if ~isfile(nativeTensor) && isfile(templateTensor)
                % Warp tensor data only when ANTs was used for normalization
                json = loadjson(options.subj.norm.log.method);
                if contains(json.method, 'ANTs')
                    fprintf('Warping tensor data into patient space...\n\n')
                    ea_ants_apply_transforms(options,...
                        [ea_space, tensorName],... % From
                        nativeTensor,... % To
                        1, ... % Useinverse is 1
                        '', ... % Reference, auto-detected
                        '', ... % Transformation, auto-detected
                        0, ... % NearestNeighbor interpolation
                        3, ... % Dimension
                        'tensor');
                else
                    warning('off', 'backtrace');
                    warning('Warping tensor data is only supported when ANTs was used for normalization! Skipping...');
                    warning('on', 'backtrace');
                end
            end

            if isfile(nativeTensor) % Scale tensor data
                tensorDir = fileparts(nativeTensor);
                tensorPrefix = subPrefix;
            end
        end

        % Scale tensor data
        if exist('tensorDir', 'var')
            fprintf('Scaling tensor data...\n\n')
            if isempty(getenv('SINGULARITY_NAME')) % Docker
                system(['docker run ', ...
                        '--volume ', ea_getearoot, 'ext_libs/OSS-DBS:/opt/OSS-DBS ', ...
                        '--volume ', tensorDir, ':/opt/Patient ', ...
                        '--rm ', dockerImage, ' ', ...
                        'python3 /opt/OSS-DBS/OSS_platform/Tensor_scaling.py /opt/Patient/', tensorPrefix, tensorName, ' ', scalingMethod]);
            else % Singularity
                system(['python3 ', ea_getearoot, 'ext_libs/OSS-DBS/OSS_platform/Tensor_scaling.py ', tensorDir, tensorPrefix, tensorName, ' ', scalingMethod]);
            end

            % Copy scaled tensor data to stimulation directory, update setting
            copyfile([tensorDir, tensorPrefix, scaledTensorName], tensorData);
            settings.DTI_data_name = scaledTensorName;
        end
    end
end

if ~isempty(settings.DTI_data_name)
    fprintf('Scaled tensor data added: %s\n\n', settings.DTI_data_name)
end

%% Index of the tissue in the segmented MRI data
settings.GM_index = 1;
settings.WM_index = 2;
settings.CSF_index = 3;

settings.default_material = 'GM'; % GM, WM or CSF

%% Electrodes information
settings.Electrode_type = options.elmodel;

% Reload reco since we need to decide whether to use native or MNI coordinates.
coords_mm = ea_load_reconstruction(options);
settings.contactLocation = coords_mm;
eleNum = length(coords_mm); % Number of electrodes

% Save both native and MNI space y and head markers for OSS-DBS
settings.yMarkerNative = nan(eleNum, 3);
settings.yMarkerMNI = nan(eleNum, 3);
settings.headNative = nan(eleNum, 3);
settings.headMNI = nan(eleNum, 3);
[markersNative, markersMNI] = ea_get_markers(options);
for i=1:eleNum
    if ~isempty(markersNative) && ~isempty(markersNative(i).y)
    	settings.yMarkerNative(i,:) = markersNative(i).y;
    end
    if ~isempty(markersMNI) && ~isempty(markersMNI(i).y)
    	settings.yMarkerMNI(i,:) = markersMNI(i).y;
    end
    if ~isempty(markersNative) && ~isempty(markersNative(i).head)
    	settings.headNative(i,:) = markersNative(i).head;
    end
    if ~isempty(markersMNI) && ~isempty(markersMNI(i).head)
    	settings.headMNI(i,:) = markersMNI(i).head;
    end
end

% Head
settings.Implantation_coordinate = nan(eleNum, 3);
for i=1:eleNum
    if ~isempty(coords_mm{i})
        settings.Implantation_coordinate(i,:) = coords_mm{i}(1,:);
    end
end

% Tail
settings.Second_coordinate = nan(eleNum, 3);
for i=1:eleNum
    if options.elspec.numel == 1 % Exception for electrode with only one contact
        if options.native
            settings.Second_coordinate(i,:) = markersNative(i).tail;
        else
            settings.Second_coordinate(i,:) = markersMNI(i).tail;
        end
    elseif ~isempty(coords_mm{i})
        settings.Second_coordinate(i,:) = coords_mm{i}(end,:);
    end
end

% Rotation around the lead axis in degrees
settings.Rotation_Z = 0.0;

%% Stimulation Information
% Set stimSetMode flag
settings.stimSetMode = options.stimSetMode;

% Initialize current control flag
settings.current_control = nan(eleNum,1);

% Initalize Phi vector
settings.Phi_vector = nan(eleNum,options.elspec.numel);

% Initialize grounding
settings.Case_grounding = zeros(eleNum,1);

% Get the stimulation parameters from S in case stimSetMode is 0, otherwise
% they will be loaded directly from the Current_protocols_[0|1].csv files
if ~settings.stimSetMode
    source = nan(eleNum,1);
    for i=1:eleNum
        if any(S.amplitude{i})
            source(i) = find(S.amplitude{i},1);
        end
    end

    % 0 - Voltage Control; 1 - Current Control
    for i=1:eleNum
        switch i
            case 1
                sideCode = 'R';
            case 2
                sideCode = 'L';
        end

        if ~isnan(source(i))
            settings.current_control(i) = uint8(S.([sideCode, 's', num2str(source(i))]).va==2);
        end
    end

    % Get stimulation amplitude
    amp = nan(eleNum,1);
    for i=1:eleNum
        if ~isnan(source(i))
            amp(i) = S.amplitude{i}(source(i));
        end
    end

    %  For VC, check all sources
    if settings.current_control(1) == 0  % both hemisphere MUST have the same mode
        numSources = 4;
        amp = nan(eleNum,numSources);   % 4 - number of sources
        for i=1:eleNum
            for j=1:numSources
                amp(i,j) = S.amplitude{i}(j);
            end
        end
    else
        amp = nan(eleNum,1);  % For CC, one source is used, add a check
        for i=1:eleNum
            if ~isnan(source(i))
                amp(i) = S.amplitude{i}(source(i));
            end
        end        
    end
    
    
    for i = 1:eleNum
        switch i
            case 1
                sideCode = 'R';
                cntlabel = {'k0','k1','k2','k3','k4','k5','k6','k7'};
            case 2
                sideCode = 'L';
                cntlabel = {'k8','k9','k10','k11','k12','k13','k14','k15'};
        end

        if ~isnan(source(i))
            stimSource = S.([sideCode, 's', num2str(source(i))]);
            
            % Split voltage in case contacts have both polarities
            if stimSource.va == 1 
                for j=1:numSources
                    v_source = S.([sideCode, 's', num2str(j)]);
                    if v_source.case.pol == 0
                        amp(i,j) = amp(i,j)/2;
                    end
                end
            end

            for cnt = 1:options.elspec.numel
                if settings.current_control(i) == 1  % only one source for CC
                    if S.activecontacts{i}(cnt)
                        switch stimSource.(cntlabel{cnt}).pol
                            case 1 % Negative, cathode
                                settings.Phi_vector(i, cnt) = -amp(i)*stimSource.(cntlabel{cnt}).perc/100;
                            case 2 % Postive, anode
                                settings.Phi_vector(i, cnt) = amp(i)*stimSource.(cntlabel{cnt}).perc/100;
                        end             
                    end
                else
                    for j=1:numSources  % go over sources
                        v_source = S.([sideCode, 's', num2str(j)]);
                        if v_source.(cntlabel{cnt}).perc    % the contact is active for this source
                            if isnan(settings.Phi_vector(i, cnt))
                                settings.Phi_vector(i, cnt) = 0.0;  % initialize
                            end
                            switch v_source.(cntlabel{cnt}).pol  % sanity check needed: same polarity for a contact over all sources
                                case 1
                                    settings.Phi_vector(i, cnt) = settings.Phi_vector(i, cnt) - amp(i,j);
                                case 2
                                    settings.Phi_vector(i, cnt) = settings.Phi_vector(i, cnt) + amp(i,j);
                            end
                        end
                    end
                end
            end
            if stimSource.case.perc == 100
                settings.Case_grounding(i) = 1;
            end
        end
    end
end

% Threshold for Astrom VTA (V/mm)
settings.Activation_threshold_VTA = options.prefs.machine.vatsettings.butenko_ethresh;

% Set stimulation protocol
if settings.stimSetMode
    stimProtocol = ea_regexpdir(outputDir, '^Current_protocols_\d\.csv$', 0);
else
    stimProtocol = S;
end

% Axon activation setting
settings.calcAxonActivation = options.prefs.machine.vatsettings.butenko_calcAxonActivation;
if settings.calcAxonActivation
    settings.connectome = options.prefs.machine.vatsettings.butenko_connectome;
    settings.axonLength = options.prefs.machine.vatsettings.butenko_axonLength;
    settings.fiberDiameter = options.prefs.machine.vatsettings.butenko_fiberDiameter;

    preopAnchor = options.subj.preopAnat.(options.subj.AnchorModality).coreg;
    if ~startsWith(settings.connectome, 'Multi-Tract: ') % Normal connectome
        fprintf('Loading connectome: %s ...\n', settings.connectome);
        conn = load([ea_getconnectomebase, 'dMRI', filesep, settings.connectome, filesep, 'data.mat']);
        if options.native
            originalFib = conn.fibers;
            % Convert connectome fibers from MNI space to anchor space
            fprintf('Convert connectome into native space...\n\n');
            fibersMNIVox = ea_mm2vox(conn.fibers(:,1:3), [ea_space, options.primarytemplate, '.nii'])';
            conn.fibers(:,1:3)  = ea_map_coords(fibersMNIVox, ...
                [ea_space, options.primarytemplate, '.nii'], ...
                [options.subj.subjDir, 'forwardTransform'], ...
                preopAnchor)';
        end

        % Filter fibers based on the spherical ROI
        if options.native
        	fiberFiltered = ea_filterfiber_stim(conn, coords_mm, stimProtocol, 'kuncel', 2, preopAnchor);
        else
            fiberFiltered = ea_filterfiber_stim(conn, coords_mm, stimProtocol, 'kuncel', 2, [ea_space, options.primarytemplate, '.nii']);
        end

        % Filter fibers based on the minimal length
        fiberFiltered = ea_filterfiber_len(fiberFiltered, settings.axonLength);

        % Move original fiber id to the 5th column, the 4th column will be 1:N
        fibersFound = zeros(size(fiberFiltered));
        for i=1:length(fiberFiltered)
            if ~isempty(fiberFiltered{i}.fibers)
                fibers = zeros(size(fiberFiltered{i}.fibers,1),5);
                fibers(:,[1,2,3,5]) = fiberFiltered{i}.fibers;
                fibers(:,4) = repelem(1:length(fiberFiltered{i}.idx), fiberFiltered{i}.idx)';
                fiberFiltered{i}.fibers = fibers;
                fibersFound(i) = 1;
            end
        end

        settings.connectomePath = [outputDir, filesep, settings.connectome];
        ea_mkdir(settings.connectomePath);
        for i=1:length(fiberFiltered)
            buffer = fiberFiltered{i};
            save([settings.connectomePath, filesep, 'data', num2str(i), '.mat'], '-struct', 'buffer', '-v7.3');
        end
    else % Multi-Tract connectome
        % Extract connectome name
        connName = strrep(settings.connectome, 'Multi-Tract: ', '');

        % Create output folder
        settings.connectomePath = [outputDir, filesep, connName];
        ea_mkdir(settings.connectomePath);

        % Get paths of tracts
        connFolder = [ea_getconnectomebase, 'dMRI_MultiTract', filesep, connName];
        tracts = ea_regexpdir(connFolder, '\.mat$', 0);

        settings.connectomeTractNames = cell(size(tracts));
        data1 = struct;
        data2 = struct;
        fibersFound = zeros(numel(tracts),2);
        for t=1:numel(tracts)
            tract = tracts{t};
            [~, tractName] = fileparts(tract);
            settings.connectomeTractNames{t} = tractName;
            fprintf('Loading connectome: %s, Tract: %s ...\n', connName, tractName);
            conn = load(tract);
            if options.native
                originalFib = conn.fibers;
                % Convert connectome fibers from MNI space to anchor space
                fprintf('Convert connectome into native space...\n\n');
                fibersMNIVox = ea_mm2vox(conn.fibers(:,1:3), [ea_space, options.primarytemplate, '.nii'])';
                conn.fibers(:,1:3)  = ea_map_coords(fibersMNIVox, ...
                    [ea_space, options.primarytemplate, '.nii'], ...
                    [options.subj.subjDir, 'forwardTransform'], ...
                    preopAnchor)';
            end

            % Filter fibers based on the spherical ROI
            fiberFiltered = ea_filterfiber_stim(conn, coords_mm, stimProtocol, 'kuncel', 2);

            % Filter fibers based on the minimal length
            fiberFiltered = ea_filterfiber_len(fiberFiltered, settings.axonLength(t));

            % Move original fiber id to the 5th column, the 4th column will be 1:N
            for i=1:length(fiberFiltered)
                if ~isempty(fiberFiltered{i}.fibers)
                    fibers = zeros(size(fiberFiltered{i}.fibers,1),5);
                    fibers(:,[1,2,3,5]) = fiberFiltered{i}.fibers;
                    fibers(:,4) = repelem(1:length(fiberFiltered{i}.idx), fiberFiltered{i}.idx)';
                    fiberFiltered{i}.fibers = fibers;
                    fibersFound(t,i) = 1;
                end
            end
            eval(['data1.', tractName, ' = fiberFiltered{1};']);
            eval(['data2.', tractName, ' = fiberFiltered{2};']);
        end

        % Save filtered fibers
        save([settings.connectomePath, filesep, 'data1.mat'], '-struct', 'data1', '-v7.3');
        save([settings.connectomePath, filesep, 'data2.mat'], '-struct', 'data2', '-v7.3');
    end
end

% Interactive mode setting
settings.interactiveMode = options.prefs.machine.vatsettings.butenko_interactive;

%% Save settings for OSS-DBS
parameterFile = [outputDir, filesep, 'oss-dbs_parameters.mat'];
save(parameterFile, 'settings', '-v7.3');


% Delete previous results from stimSetMode
ea_delete([outputDir, filesep, 'Result_StimProt_*']);
ea_delete([templateOutputDir, filesep, 'Result_StimProt_*']);

%% Run OSS-DBS
libpath = getenv('LD_LIBRARY_PATH');
setenv('LD_LIBRARY_PATH', ''); % Clear LD_LIBRARY_PATH to resolve conflicts

% Delete flag files before running
ea_delete([outputDir, filesep, 'success_rh.txt']);
ea_delete([outputDir, filesep, 'fail_rh.txt']);
ea_delete([outputDir, filesep, 'skip_rh.txt']);
ea_delete([outputDir, filesep, 'success_lh.txt']);
ea_delete([outputDir, filesep, 'fail_lh.txt']);
ea_delete([outputDir, filesep, 'skip_lh.txt']);

% Iterate sides, index side: 0 - rh , 1 - lh
runStatus = [0 0]; % Succeed or not
stimparams = struct();
for side=0:1
    % Stop and Remove running docker container on start
    if isempty(getenv('SINGULARITY_NAME')) % Only do it when using docker
        [~, containerID] = system(['docker ps -qf ancestor=', dockerImage]);
        if ~isempty(containerID)
            containerID = strsplit(strip(containerID));
            fprintf('\nStop running container...\n')
            cellfun(@(id) system(['docker stop ', id, newline]), containerID);
            % fprintf('\nClean up running container...\n')
            % cellfun(@(id) system(['docker rm ', id, newline]), containerID);
        end
    end

    switch side
        case 0
            sideLabel = 'R';
            sideCode = 'rh';
            sideStr = 'right';
        case 1
            sideLabel = 'L';
            sideCode = 'lh';
            sideStr = 'left';
    end

    if ~settings.stimSetMode && isnan(settings.current_control(side+1))
        warning('off', 'backtrace');
        warning('No stimulation exists for %s side! Skipping...\n', sideStr);
        warning('on', 'backtrace');
        fclose(fopen([outputDir, filesep, 'skip_', sideCode, '.txt'], 'w'));
        continue;
    end

    if settings.calcAxonActivation && ~any(fibersFound(:,side+1))
        warning('off', 'backtrace');
        warning('No fibers found for %s side! Skipping...\n', sideStr);
        warning('on', 'backtrace');
        fclose(fopen([outputDir, filesep, 'skip_', sideCode, '.txt'], 'w'));
        continue;
    end

    fprintf('\nRunning OSS-DBS for %s side stimulation...\n\n', sideStr);

    % Calculate axon allocation when option enabled
    if settings.calcAxonActivation
        fprintf('Calculating axon allocation for %s side stimulation...\n\n', sideStr);

        % Make sure to clean up, useful in manually interruption
        ea_delete([outputDir, filesep, 'Brain_substitute.brep']);
        ea_delete([outputDir, filesep,'Allocated_axons.h5']);
        ea_delete(ea_regexpdir(outputDir, '^(?!Current_protocols_).*\.csv$', 0));
        ea_delete([outputDir, filesep,'*.py']);

        % Delete this folder in MATLAB since shutil.rmtree may raise I/O error
        % ea_delete([outputDir, filesep,'Axons_in_time']);

        % fprintf('ea_getearoot %s \n\n', ea_getearoot)
        % fprintf('outputDir %s \n\n', outputDir)
        % fprintf('num2str(side) %s \n\n', num2str(side))

        if isempty(getenv('SINGULARITY_NAME')) % Docker
            system(['docker run ', ...
                    '--volume ', ea_getearoot, 'ext_libs/OSS-DBS:/opt/OSS-DBS ', ...
                    '--volume ', outputDir, ':/opt/Patient ', ...
                    '--rm ', dockerImage, ' ', ...
                    'python3 /opt/OSS-DBS/OSS_platform/Axon_allocation.py /opt/Patient ', num2str(side)]);
        else % Singularity
            system(['python3 ', ea_getearoot, 'ext_libs/OSS-DBS/OSS_platform/Axon_allocation.py ', outputDir, ' ', num2str(side)]);
        end
    end

    % Call OSS-DBS GUI to start calculation
    system([pythonBinName, ' ', ea_getearoot, 'ext_libs/OSS-DBS/OSS_platform/OSS-DBS_LeadDBS_integrator.py ', ...
            parameterFile, ' ', num2str(side)]);	% 0 is right side, 1 is the left side here

    % Check if OSS-DBS calculation is finished
    while ~isfile([outputDir, filesep, 'success_', sideCode, '.txt']) ...
            && ~isfile([outputDir, filesep, 'fail_', sideCode, '.txt'])
        continue;
    end

    % Get resultfig handle
    if exist('hFigure', 'var')
        resultfig = getappdata(hFigure,'resultfig');
    end

    if isfile([outputDir, filesep, 'success_', sideCode, '.txt'])
        runStatus(side+1) = 1;
        fprintf('\nOSS-DBS calculation succeeded!\n\n')
        % Copy VAT files
        if isfile([outputDir, filesep, 'Results_', sideCode, filesep, 'E_field_solution.nii'])
            copyfile([outputDir, filesep, 'Results_', sideCode, filesep, 'E_field_solution.nii'], ...
                     [outputBasePath, 'efield_hemi-', sideLabel, '.nii'])
            if options.native % Transform to MNI space
                ea_apply_normalization_tofile(options,...
                    [outputBasePath, 'efield_hemi-', sideLabel, '.nii'],... % from
                    [templateOutputBasePath, 'efield_hemi-', sideLabel, '.nii'],... % to
                    0, ... % useinverse is 0
                    1, ... % linear interpolation
                    [ea_space, options.primarytemplate, '.nii']);
                ea_autocrop([templateOutputBasePath, 'efield_hemi-', sideLabel, '.nii']);
            end
        end

        if isfile([outputDir, filesep, 'Results_', sideCode, filesep, 'VTA_solution.nii'])
            copyfile([outputDir, filesep, 'Results_', sideCode, filesep, 'VTA_solution.nii'], ...
                     [outputBasePath, 'binary_hemi-', sideLabel, '.nii'])

            vatToViz = [outputBasePath, 'binary_hemi-', sideLabel, '.nii'];
            if options.native % Transform to MNI space
                ea_apply_normalization_tofile(options,...
                    [outputBasePath, 'binary_hemi-', sideLabel, '.nii'],... % from
                    [templateOutputBasePath, 'binary_hemi-', sideLabel, '.nii'],... % to
                    0, ... % useinverse is 0
                    0, ... % nn interpolation
                    [ea_space, options.primarytemplate, '.nii']);
                ea_autocrop([templateOutputBasePath, 'binary_hemi-', sideLabel, '.nii']);

                if ~options.orignative % Visualize MNI space VTA
                    vatToViz = [templateOutputBasePath, 'binary_hemi-', sideLabel, '.nii'];
                end
            end

            % Calc vat fv and volume
            vat = ea_load_nii(vatToViz);
            vatfv = ea_niiVAT2fvVAT(vat);
            vatvolume = sum(vat.img(:))*vat.voxsize(1)*vat.voxsize(2)*vat.voxsize(3);
            save(strrep(vatToViz, '.nii', '.mat'), 'vatfv', 'vatvolume');
            stimparams(side+1).VAT.VAT = vatfv;
            stimparams(side+1).volume = vatvolume;
        end

        axonState = ea_regexpdir([outputDir, filesep, 'Results_', sideCode], 'Axon_state.*\.mat', 0);
        if ~isempty(axonState)
            for f=1:length(axonState)

                % Determine tract name
                if startsWith(settings.connectome, 'Multi-Tract: ')
                    tractName = regexp(axonState{f}, '(?<=Axon_state_).+(?=\.mat$)', 'match', 'once');
                end

                % If stimSetMode, extract the index from tractName (but axonState is still checked on the indexed file)
                if settings.stimSetMode
                    if startsWith(settings.connectome, 'Multi-Tract: ')
                        stimProt_index = regexp(tractName, '(?<=_)\d+$', 'match', 'once');
                        tractName = regexprep(tractName, '.+(?=_\d+$)', 'match', 'once');
                    else
                        stimProt_index = regexp(axonState{f}, '(?<=Axon_state_)\d+(?=\.mat$)', 'match', 'once');
                    end
                end

                % Get fiber id and state from OSS-DBS result
                ftr = load(axonState{f});
                [fibId, ind] = unique(ftr.fibers(:,4));
                fibState = ftr.fibers(ind,5);

                % Restore full length fiber (as in original filtered fiber)
                if startsWith(settings.connectome, 'Multi-Tract: ')
                    ftr = load([settings.connectomePath, filesep, 'data', num2str(side+1), '.mat'], tractName);
                    ftr = ftr.(tractName);
                    ftr.connectome_name = connName;
                else
                    ftr = load([settings.connectomePath, filesep, 'data', num2str(side+1), '.mat']);
                    ftr.connectome_name = settings.connectome;
                end
                ftr.fibers = ftr.fibers(ismember(ftr.fibers(:,4), fibId), :);
                originalFibID = ftr.fibers(:,5);

                % Extract original conn fiber id and idx, needed in case
                % calculation is done in native space
                [connFibID, idx] = unique(ftr.fibers(:,5));

                % Set fiber state
                for fib=1:length(fibId)
                    ftr.fibers(ftr.fibers(:,4)==fibId(fib),5) = fibState(fib);
                end

                % Extract state of original conn fiber, needed in case
                % calculation is  done in native space
                connFibState = ftr.fibers(idx, 5);

                % Reset original fiber id as in the connectome
                ftr.fibers(:,4) = originalFibID;

                % Save result for visualization

                % If stimSets, save to a corresponding folder
                if settings.stimSetMode
                    resultProtocol = [outputDir, filesep, 'Result_StimProt_', sideStr, '_', stimProt_index];
                    ea_mkdir(resultProtocol);
                    if startsWith(settings.connectome, 'Multi-Tract: ')
                        fiberActivation = [resultProtocol, filesep, filePrefix, 'fiberActivation_hemi-', sideLabel, '_tract-', tractName,'_prot-', stimProt_index, '.mat'];
                    else
                        fiberActivation = [resultProtocol, filesep, filePrefix, 'fiberActivation_hemi-', sideLabel,'_prot-', stimProt_index, '.mat'];
                    end
                else
                    if startsWith(settings.connectome, 'Multi-Tract: ')
                        fiberActivation = [outputBasePath, 'fiberActivation_hemi-', sideLabel, '_tract-', tractName, '.mat'];
                    else
                        fiberActivation = [outputBasePath, 'fiberActivation_hemi-', sideLabel, '.mat'];
                    end
                end

                save(fiberActivation, '-struct', 'ftr');

                if options.native % Generate fiber activation file in MNI space
                    fprintf('Restore connectome in MNI space: %s ...\n\n', settings.connectome);
                    conn.fibers = originalFib;

                    fprintf('Convert fiber activation result into MNI space...\n\n');
                    conn.fibers = conn.fibers(ismember(conn.fibers(:,4), connFibID), :);
                    % Set fiber state
                    conn.fibers = [conn.fibers, zeros(size(conn.fibers,1),1)];
                    for fib=1:length(connFibID)
                        conn.fibers(conn.fibers(:,4)==connFibID(fib),5) = connFibState(fib);
                    end

                    % Recreate fiber idx
                    [~, ~, idx] = unique(conn.fibers(:,4), 'stable');
                    conn.idx = accumarray(idx,1);

                    % Reset original fiber id as in the connectome
                    ftr.fibers(:,4) = originalFibID;

                    % Save MNI space fiber activation result

                    % If stimSets, save to a corresponding folder
                    if settings.stimSetMode
                        resultProtocol = [templateOutputDir, filesep, 'Result_StimProt_', sideStr, '_', stimProt_index];
                        ea_mkdir(resultProtocol);
                        if startsWith(settings.connectome, 'Multi-Tract: ')
                            fiberActivationMNI = [resultProtocol, filesep, filePrefix, 'fiberActivation_hemi-', sideLabel, '_tract-', tractName,'_prot-', stimProt_index, '.mat'];
                        else
                            fiberActivationMNI = [resultProtocol, filesep, filePrefix, 'fiberActivation_hemi-', sideLabel, '_prot-', stimProt_index, '.mat'];
                        end
                    else
                        if startsWith(settings.connectome, 'Multi-Tract: ')
                            fiberActivationMNI = [templateOutputBasePath, filesep, 'fiberActivation_hemi-', sideLabel, '_tract-', tractName, '.mat'];
                        else
                            fiberActivationMNI = [templateOutputBasePath, filesep, 'fiberActivation_hemi-', sideLabel, '.mat'];
                        end
                    end
                    save(fiberActivationMNI, '-struct', 'conn');

                    if ~options.orignative % Visualize MNI space result
                        fiberActivation = fiberActivationMNI;
                    end
                end

                % Visualize fiber activation, but not for stimSetMode
                if ~settings.stimSetMode
                    if exist('resultfig', 'var')
                        set(0, 'CurrentFigure', resultfig);
                        ea_fiberactivation_viz(fiberActivation, resultfig);
                    end
                end
            end
        end
    elseif isfile([outputDir, filesep, 'fail_', sideCode, '.txt'])
        fprintf('\n')
        warning('off', 'backtrace');
        warning('OSS-DBS calculation failed for %s side!\n', sideStr);
        warning('on', 'backtrace');
    end

    % Clean up
    ea_delete([outputDir, filesep, 'Brain_substitute.brep']);
    ea_delete([outputDir, filesep, 'Allocated_axons.h5']);
    ea_delete(ea_regexpdir(outputDir, '^(?!Current_protocols_).*\.csv$', 0));
    % ea_delete([outputDir, filesep, '*.py']);

    % Delete this folder in MATLAB since shutil.rmtree may raise
    % I/O error
    % ea_delete([outputDir, filesep, 'Axons_in_time']);
end

varargout{1} = runStatus;

if ~settings.calcAxonActivation && exist('stimparams', 'var')
    varargout{2} = stimparams;
end

% Restore working directory and environment variables
setenv('LD_LIBRARY_PATH', libpath);
setenv('PATH', binPath);


%% Helper function to get markers in bothe native and MNI space
function [markersNative, markersMNI] = ea_get_markers(options)
options.native = 1;
try
    [~, ~, markersNative] = ea_load_reconstruction(options);
catch
    markersNative = [];
    fprintf('\n')
    warning('off', 'backtrace');
    warning('Failed to load native reconstruction!');
    warning('on', 'backtrace');
end

options.native = 0;
try
    [~, ~, markersMNI] = ea_load_reconstruction(options);
catch
    markersMNI = [];
    fprintf('\n')
    warning('off', 'backtrace');
    warning('Failed to load MNI reconstruction!');
    warning('on', 'backtrace');
end
