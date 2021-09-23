function ea_patch_spm
% Patch SPM def and norm cfg file to make deformation file whose name does
% not start with 'y_*' or 'iy_*' also recognizable.

defCfgFile = [fileparts(which('spm')), filesep, 'config', filesep, 'spm_cfg_deformations.m'];
defCfg = fileread(defCfgFile);
if contains(defCfg, '.*y_.*\.nii$')
    defCfg = strrep(defCfg, '.*y_.*\.nii$', '.*\.nii$');
    fid = fopen(defCfgFile, 'w');
    fprintf(fid, '%s', defCfg);
    fclose(fid);
end

normCfgFile = [fileparts(which('spm')), filesep, 'config', filesep, 'spm_cfg_norm.m'];
normCfg = fileread(normCfgFile);
if contains(normCfg, 'y_.*\.nii$')
    normCfg = strrep(normCfg, 'y_.*\.nii$', '.*\.nii$');
    fid = fopen(normCfgFile, 'w');
    fprintf(fid, '%s', normCfg);
    fclose(fid);
end
