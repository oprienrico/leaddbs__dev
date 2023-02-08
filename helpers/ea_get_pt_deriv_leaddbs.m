function [deriv_uipatdir,BIDSRoot,subjId] = ea_get_pt_deriv_leaddbs(uipatdir)

    if iscell(uipatdir)
        uipatdir=uipatdir{1};
    end
    
    uipatdir = GetFullPath(uipatdir);
    
    isSubjFolder = 0;
    isBIDSRoot = 0;


    %subjDerivativesFolder = fullfile(BIDSRoot, 'derivatives', 'leaddbs', ['sub-', subjId{1}]);

    %subjId = regexp(uipatdir, ['sub-).*'], 'match');

    if contains(uipatdir, ['derivatives', filesep, 'leaddbs']) % Is patient folder under derivatives
        isSubjFolder = 1;
        BIDSRoot = regexp(uipatdir, ['^.*(?=\', filesep, 'derivatives)'], 'match', 'once');
        subjId = regexp(uipatdir, ['(?<=leaddbs\', filesep, 'sub-).*'], 'match');
        deriv_uipatdir=uipatdir;%it is the same folder
    else % Check if it's BIDS root folder
        folders = dir(uipatdir);
        folders = {folders.name};
        if ismember('sourcedata', folders) || ismember('rawdata', folders) || ismember('derivatives', folders)
            isBIDSRoot = 1;
            BIDSRoot = uipatdir;
            ea_checkSpecialChars(BIDSRoot);
            derivativesData = ea_regexpdir([uipatdir, filesep, 'derivatives', filesep, 'leaddbs'], 'sub-', 0, 'dir');
            derivativesData = regexprep(derivativesData, ['\', filesep, '$'], '');

            deriv_uipatdir = derivativesData{1};
            subjId = regexp(derivativesData, ['(?<=leaddbs\', filesep, 'sub-).*'], 'match', 'once');
        else
            error('not a lead dbs patient folder')
        end

    end

end

