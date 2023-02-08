function [deriv_uipatdirs,BIDSRoots,subjIds] = ea_get_pts_deriv_leaddbs(uipatdirs)

    if ~iscell(uipatdirs)
        uipatdirs={uipatdirs};
    end
    
    uipatdirs = GetFullPath(uipatdirs);

    deriv_uipatdirs=cell(size(uipatdirs));
    BIDSRoots=cell(size(uipatdirs));
    subjIds=cell(size(uipatdirs));

    for path_i=1:length(uipatdirs)
        [deriv_uipatdir,BIDSRoot,subjId] = ea_get_pt_deriv_leaddbs(uipatdirs{path_i});

        deriv_uipatdirs{path_i}=deriv_uipatdir;
        BIDSRoots{path_i}=BIDSRoot;
        subjIds{path_i}=subjId;
    end