function ea_options2handles(options,handles)

% set handles
set(handles.dicomcheck,'Value',options.dicomimp.do);
set(handles.normalize_checkbox,'Value',options.normalize.do);
if options.normalize.methodn>length(handles.normmethod.String)
    set(handles.normmethod,'Value',1);
else
    set(handles.normmethod,'Value',options.normalize.methodn);
end
set(handles.normcheck,'Value',options.normalize.check);

% CT coregistration
set(handles.coreg_checkbox,'Value',options.coregct.do);
if options.coregct.methodn>length(handles.coregctmethod.String)
    set(handles.coregctmethod,'Value',1);
else
    set(handles.coregctmethod,'Value',options.coregct.methodn);
end

if isfield(options, 'normcheck')
    set(handles.normcheck, 'Value', options.normcheck);
end

set(handles.MRCT,'Value',options.modality);

for i=1:15
    if ismember(i,options.sides)
        set(handles.(['side', num2str(i)]), 'Value', 1);
    else
        set(handles.(['side', num2str(i)]), 'Value', 0);
    end
end

set(handles.doreconstruction_checkbox,'Value',options.doreconstruction);

if options.automask
    set(handles.maskwindow_txt,'String','auto')
else
    set(handles.maskwindow_txt,'String',num2str(options.maskwindow));
end

set(handles.writeout2d_checkbox,'Value',options.d2.write);
set(handles.manualheight_checkbox,'Value',options.manualheightcorrection);
set(handles.render_checkbox,'Value',options.d3.write);
set(handles.targetpopup,'Value',options.entrypointn);
set(handles.electrode_model_popup,'Value',options.elmodeln);
set(handles.atlassetpopup,'Value',options.atlassetn);
set(handles.exportservercheck,'Value',options.d3.autoserver);
