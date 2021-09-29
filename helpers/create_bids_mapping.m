function [brainshift,coregistration,normalization,preprocessing,reconstruction,prefs,stimulations,headmodel,miscellaneous,ftracking,log] = create_bids_mapping()
%create a list of old files along with their full path:
%%

brainshift{:,1} =      {'anat_t1.nii';...
                        'movim.nii';...
                        'bgmsk.nii';...
                        'bgmsk2.nii';...
                        'scrfmovim.nii';...
                        'scrf_instore.mat';...
                        'scrf_converted.mat';...
                        'scrf_instore_converted.mat';...
                        'standard.png';...
                        'scrf.png';
                        'ea'};
brainshift{:,2} =       {'space-anchorNative_rec-brainshift_desc-preproc_ses-preop_T1w.nii';...
                         'space-anchorNative_rec-tonemapped_desc-preproc_ses-postop_CT.nii';...
                         'space-anchorNative_desc-secondstepmask.nii';...
                         'space-anchorNative_desc-thirdstepmask.nii';...
                         'space-anchorNative_rec-tonemappedbrainshift_desc-preproc_ses-postop_CT.nii';...
                         'from-anchorNative_to-anchorNativeBSC_desc-instore.mat';...
                         'from-anchorNative_to-anchorNativeBSC_desc-converted.mat';...
                         'from-anchorNative_to-anchorNativeBSC_desc-scrf.mat';...
                         'space-anchorNative_rec-tonemapped_desc-preproc_ses-postop_CT.png';...
                         'space-anchorNative_rec-tonemappedbrainshift_desc-preproc_ses-postop_CT.png'};

coregistration{:,1} =   {'rpostop_ct.nii';...
                'postop_tra.nii';...
                'postop_cor.nii';...
                'postop_sag.nii';...
                'anat_t1.nii';...
                'anat_t2.nii';...
                'anat_fgatir.nii';...
                'anat_pd.nii';...
                'anat_flair.nii';...
                'anat_t2star.nii';...
                'tp_rpostop_ct.nii';...
                'c1anat.nii';...
                'c2anat.nii';...
                'c3anat.nii';...
                'c1anat_t2.nii';...
                'c2anat_t2.nii';...
                'c3anat_t2.nii';...
                'fa2anat.nii';...
                'anat_t22anat_t1.png';...
                'anat_t2star2anat_t1.png';...
                'anat_pd2anat_t1.png';...
                'anat_flair2anat_t1.png';...
                'anat_fgatir2anat_t1.png';...
                'rpostop_ct2anat_t1.png';...
                'tp_rpostop_ct2anat_t1.png';...
                'tp_rpostop_ct2anat_t1_ea_coregctmri_ants.png';...
                'ea_coreg_approved.mat';...
                'ea_coregctmethod_applied.mat';...
                'ea_coregmrimethod_applied.mat';...
                'anat_t12postop_ct_ants1.mat';...
                'ea_precoregtransformation.mat';
                'postop_ct2anat_t1_ants1.mat';...
                'anat_t12b0_spm.mat';...
                'b02anat_t1_spm.mat'};
            
coregistration{:,2} =  {'space-anchorNative_desc-preproc_ses-postop_CT.nii';...
                 'space-anchorNative_desc-preproc_ses-postop_acq-ax_MRI.nii';...
                'space-anchorNative_desc-preproc_ses-postop_acq-cor_MRI.nii';...
                'space-anchorNative_desc-preproc_ses-postop_acq-sag_MRI.nii';...
                'space-anchorNative_desc-preproc_ses-preop_T1w.nii';...
                'space-anchorNative_desc-preproc_ses-preop_T2w.nii';...
                'space-anchorNative_desc-preproc_ses-preop_FGATIR.nii';...
                'space-anchorNative_desc-preproc_ses-preop_PDw.nii';...
                'space-anchorNative_desc-preproc_ses-preop_FLAIR.nii';...
                'space-anchorNative_desc-preproc_ses-preop_T2starw.nii';...
                'space-anchorNative_rec-tonemapped_desc-preproc_ses-postop_CT.nii';...
                'space-anchorNative_desc-preproc_ses-preop_label-GM_mod-T1w_mask.nii';...
                'space-anchorNative_desc-preproc_ses-preop_label-WM_mod-T1w_mask.nii';...
                'space-anchorNative_desc-preproc_ses-preop_label-CSF_mod-T1w_mask.nii';...
                'space-anchorNative_desc-preproc_ses-preop_label-GM_mod-T2w_mask.nii';...
                'space-anchorNative_desc-preproc_ses-preop_label-WM_mod-T2w_mask.nii';...
                'space-anchorNative_desc-preproc_ses-preop_label-CSF_mod-T2w_mask.nii';...
                'space-anchorNative_desc-preproc_ses-postop_acq-fa.nii';...
                'space-anchorNative_desc-preproc_T2w.png';...
                'space-anchorNative_desc-preproc_T2starw.png';...
                'space-anchorNative_desc-preproc_PDw.png';...
                'space-anchorNative_desc-preproc_FLAIR.png';...
                'space-anchorNative_desc-preproc_FGATIR.png';...
                'space-anchorNative_desc-preproc_ses-postop_CT.png';...
                'space-anchorNative_rec-tonemapped_desc-preproc_CT.png';...
                'space-anchorNative_rec-tonemapped_desc-preproc_CT.png';...
                'desc-coregmethod.mat';...
                'desc-coregCTmethod_applied.mat';...
                'desc-coregMRmethod_applied.mat';...
                'from-anchorNative_to-CT_desc-ants.mat';...
                'desc-precoreg_T1w.mat';...
                'from-CT_to-anchorNative_desc-ants.mat';...
                'from-b0_to-anchorNative_desc-spm.mat';...
                'from-anchorNative_to-b0_desc-spm.mat'};
            
normalization{:,1}  = {'glpostop_ct.nii';...
                       'glpostop_tra.nii';...
                       'glpostop_cor.nii';...
                       'glpostop_sag.nii';...
                       'glanat_t1.nii';...
                       'glanat.nii';...
                       'tp_glpostop_ct.nii';...
                       'glfa2anat.nii';...
                       'glanat_fgatir.nii';...
                       'glanat_t2.nii';...
                       'glanat_pd.nii';...
                       'glanat_t2star.nii';...
                       'glanat_flair.nii';...
                       'glanat2t1_ea_normalize_ants.png';...
                       'glpostop_cor2t1_ea_normalize_ants.png';...
                       'glpostop_sag2t1_ea_normalize_ants.png';...
                       'glpostop_tra2t1_ea_normalize_ants.png';...
                       'glpostop_ct_ea_normalize_ants.png';...
                       'tp_glpostop_ct2t1_ea_normalize_ants.png';...
                       'ea_normmethod_applied.mat';...
                       'ea_ants_command.txt';...
                       'glanatComposite.nii.gz';...
                       'glanatInverseComposite.nii.gz';...
                       'glanatComposite.h5';...
                       'glanatInverseComposite.h5'};
                   
normalization{:,2} = {'space-MNI152NLin2009bAsym_desc-preproc_ses-postop_CT.nii';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-postop_acq-ax_MRI.nii';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-postop_acq-cor_MRI.nii';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-postop_acq-sag_MRI.nii';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-preop_T1w.nii';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-preop_T1w.nii';...
                      'space-MNI152NLin2009bAsym_rec-tonemapped_desc-preproc_ses-postop_CT.nii';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-preop_fa.nii';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-preop_FGATIR.nii';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-preop_T2w.nii';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-preop_PDw.nii';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-preop_T2starw.nii';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-preop_FLAIR.nii';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-preop_T1w.png';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-postop_acq-cor_MRI.png';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-postop_acq-sag_MRI.png';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-postop_acq-ax_MRI.png';...
                      'space-MNI152NLin2009bAsym_desc-preproc_ses-postop_CT.png';...
                      'space-MNI152NLin2009bAsym_rec-tonemapped_desc-preproc_ses-postop_CT.png';...
                      'desc-normmethod.mat';...
                      'desc-antscmd.txt';...
                      'from-anchorNative_to-MNI152NLin2009bAsym_desc-ants.nii.gz';...
                      'from-MNI152NLin2009bAsym_to-anchorNative_desc-ants.nii.gz';...
                      'from-anchorNative_to-MNI152NLin2009bAsym_desc-ants.h5';...
                      'from-MNI152NLin2009bAsym_to-anchorNative_desc-ants.h5'};

preprocessing{:,1} = {'postop_ct.nii';...
               'raw_postop_tra.nii';...
               'raw_postop_cor.nii';...
               'raw_postop_sag.nii';...
               'raw_anat_t1.nii';...
               'raw_anat_t2.nii';...
               'raw_anat_t2star.nii';...
               'raw_anat_flair.nii';...
               'raw_anat_fgatir.nii';...
               'raw_anat_pd.nii';...
               'raw_fa.nii'};
           
preprocessing{:,2} = {'desc-preproc_ses-postop_CT.nii';...
                'desc-preproc_ses-postop_ax.nii';...
                'desc-preproc_ses-postop_cor.nii';...
                'desc-preproc_ses-postop_sag.nii';...
                'desc-preproc_ses-preop_T1w.nii';...
                'desc-preproc_ses-preop_T2w.nii';...
                'desc-preproc_ses-preop_T2starw.nii';...
                'desc-preproc_ses-preop_FLAIR.nii';...
                'desc-preproc_ses-preop_FGATIR.nii';...
                'desc-preproc_ses-preop_PDw.nii';...
                'desc-preproc_ses-postop_fa.nii'};

reconstruction{:,1} = {'ea_reconstruction.mat';
     'rct_mask.nii';...
     'ct_mask.nii'};
reconstruction{:,2} = {'desc-reconstruction.mat';...
              'space-rawCT_desc-brainmask.nii';...
              'space-anchorNative_desc-brainmask.nii'};

%%
prefs{:,1} = {'ea_ui.mat'};
prefs{:,2} = {'desc-uiprefs.mat'};

log{:,1} = {'ea_methods.txt';'ea_stats.mat';'ea_stats_backup.mat'};
log{:,2} = {'desc-methods.txt';'desc-stats.mat';'desc-stats_backup.mat'};


stimulations{:,1} = {'fl_vat_efield_left.nii';...
                     'fl_vat_efield_right.nii';...
                     'vat_efield_gauss_left.nii';...
                     'vat_efield_gauss_right.nii';...
                     'vat_efield_left.nii';...
                     'vat_efield_right.nii';...
                     'vat_left.nii';...
                     'vat_right.nii';...
                     'vat_left.mat';...
                     'vat_right.mat'};
                 
stimulations{:,2} = {'desc-efield_hemi-leftflipped.nii';...
                     'desc-efield_hemi-rightflipped.nii';...
                     'desc-efieldgauss_hemi-left.nii';...
                     'desc-efieldgauss_hemi-right.nii';...
                     'desc-efield_hemi-left.nii';...
                     'desc-efield_hemi-right.nii';...
                     'desc-stimvol_hemi-left.nii';...
                     'desc-stimvol_hemi-right.nii';...
                     'desc-stimvol_hemi-left.mat';...
                     'desc-stimvol_hemi-right.mat'};
                 
                 
headmodel{:,1} = {'headmodel1.mat';...
                  'headmodel2.mat';...
                  'hmprotocol1.mat';...
                  'hmprotocol2.mat'};
headmodel{:,2} = {'desc-headmodel1.mat';...
                  'desc-headmodel2.mat';...
                  'desc-hmprotocol1.mat';...
                  'desc-hmprotocol2.mat'};
              
ftracking{:,1} = {'b0.nii';...
                   'fa.nii';...
                   'FTR_anat.trk';...
                   'FTR_anat.mat';...
                   'ea_ftmethodapplied.mat';...
                   'ea_ftupsampling.mat';...
                   'FTR.trk';...
                   'FTR.mat';...
                   'FTR.fib.gz';...
                   'trackingmask.nii';...
                   'ttrackingmask.nii'
                   };
ftracking{:,2} = { 'b0.nii';...
                   'fa.nii';...
                   'FTR_anat.trk';...
                   'FTR_anat.mat';...
                   'ea_ftmethodapplied.mat';...
                   'ea_ftupsampling.mat';...
                   'FTR.trk';...
                   'FTR.mat';...
                   'FTR.fib.gz';...
                   'trackingmask.nii';...
                   'ttrackingmask.nii'
                   };
              
 miscellaneous{:,1} = {'rc1anat.nii';...
              'rc2anat.nii';...
              'rc3anat.nii';...
              'rc1anat_t2.nii';...
              'rc2anat_t2.nii';...
              'rc3anat_t2.nii';...
              'u_rc1anat_t2.nii';...
              'u_rc1anat.nii';...
              'Template_0.nii';...
              'Template_1.nii';...
              'Template_2.nii';...
              'Template_3.nii';...
              'Template_4.nii';...
              'Template_5.nii';...
              'Template_6.nii';...
              'ACPC_autodetect.mat';...
              'cuts_export_coordinates.txt';...
              'ea_pm_group_1.nii';...
              'ea_pm.nii';...
              'ea_pseudonym.mat';...
              'glanat0GenericAffine_backup.mat';...
              'lpost.nii';...
              'Slicer_normalized.mrml';...
              'slicer.py';...
              'Stim1.mat'};

return 
end
