function modality = ea_getmodality(BIDSFilePath, acq)
% Extract image modality from BIDS file path

% Keep acq label by default
if ~exist('acq', 'var')
    acq = 1;
end

if ~acq % Skip plane label
    modality = regexp(BIDSFilePath, '(?<=_)([^\W_]+)(?=\.nii(\.gz)?$)', 'match', 'once');
    modality = regexp(BIDSFilePath, '(?<=_acq-)((ax|sag|cor|iso)_[^\W_]+)(?=\.nii(\.gz)?$)', 'match', 'once');
else % Keep plane label
end
