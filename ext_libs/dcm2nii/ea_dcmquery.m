function [numDICOM, isCompressed] = ea_dcmquery(inputFolder)
% Check the number of DICOM file(s) in the specified folder

basedir = fullfile(ea_getearoot, 'ext_libs', 'dcm2nii', filesep);

if ispc
    dcm2niix = ea_path_helper([basedir, 'dcm2niix.exe']);
else
    dcm2niix = [basedir, 'dcm2niix.', computer('arch')];
end

cmd = [dcm2niix, ' -q y', ' ', ea_path_helper(inputFolder)];

if ~ispc
    [status, cmdout] = system(['bash -c "', cmd, '"']);
else
    [status, cmdout] = system(cmd);
end

isCompressed = false;

if status ~= 0
    ea_cprintf('CmdWinWarnings', [regexp(strip(cmdout), '(?<=\n)Error[^\n]+', 'match', 'once'), '\n']);
    numDICOM = 0;
else
    ea_cprintf('CmdWinWarnings', [regexp(strip(cmdout), '(?<=\n)Found[^\n]+', 'match', 'once'), '\n']);
    numDICOM = str2double(regexp(cmdout, '(?<=Found )\d+(?= DICOM)', 'match', 'once'));
    if contains(cmdout, 'Decompression', 'IgnoreCase', true)
        isCompressed = true;
    end
end
