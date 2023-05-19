function S = S_list_cons(file,row)
% Constructs an S (stimulate) struct based on a row in the table
% Table can be either of raw or of formatted type

addpath("leaddbs__dev\")
%addpath("leaddbs__dev\helpers")

sides = ['R' 'L'];
klit = 'k';
lbl_conv_col = 'lbl_convention';
lead_type_col = 'lead_type';
case_code = 'C';

S =  empty_S();


% Abbreviated csv type
if ismember({lbl_conv_col},file.Properties.VariableNames)
    %% This program is written to only support source 1
    source = 's1';

    % Check the label convention
    %% This program only supports medtornic label convention
    if strcmp(file{row,lbl_conv_col}{1}, 'medtronic')

        % Split the abbreviation into its contact codes by converting all
        % of the minuses into plusses and then splitting the char array with
        % + as the delimiter
        abbr = file{row,'contact_lbl'}{1};
        all_plus = abbr;
        all_plus(strfind(all_plus,'-')) = '+';
        cntct_codes = strsplit(all_plus,'+');
        % strsplit includes an empty element at the end.  Let's remove that
        % since we don't want to worry about it
        cntct_codes = cntct_codes(1:end-1);

        % odes is an array s.t. for all 0 < i <= length(odes),
        % odes(i) is 1 if the contact with code cntct_codes{i} is set to be 
        % a cathode and odes(i) is 2 if the contact with code
        % contact_codes{i} is set to be an anode
        odes = zeros(length(cntct_codes),1);
        abbr_itr = 1;
        for i = 1:length(cntct_codes)
            % Bump the abbreviation iterator to land on the +/- to see
            % whether the current contact code is a cathode or an anode
            abbr_itr = abbr_itr + length(cntct_codes{i});
            % Cathode is represented by a 1
            if strcmp(abbr(abbr_itr), '-')       
                odes(i) = 1;
            % Anode is represented by a 2
            else
                odes(i) = 2;
            end
            abbr_itr = abbr_itr + 1;
        end

        % Find which side the stimulation is activating
        s = which_side(cntct_codes);

        % Automatically set the amplitude and make it current controlled
        % because we're only interested in current controlled
        % .va means voltage activated, so setting this to 0 will make it
        % current controlled
        S.([sides(s) source]).amp=file{row,'amp'};
        S.([sides(s) source]).va=0;

        % Calculate what percentage each contact is going to have
        % We're assuming that the percentage will be evenly divided
        % among contacts that are all part of the same cathode/anode
        if count(abbr,'+') == 0 || count(abbr,'-') == 0
            error(['Failed to specify either a cathode or an anode in stimulation' file{row,'stimulation'}{1}])
        end
        cat_perc = 100/count(abbr,'-');
        an_perc = 100/count(abbr,'+');
        percs = [cat_perc an_perc];

        % If segmented
        if strcmp(file{row,lead_type_col}{1},'seg')

            % If the lead is segmented, we need to account for how, if
            % there's a contact code for a segmented level (contacts 1, 2, 9, or 10)
            % that is not followed by a letter, it signifies how A, B, and
            % C should be active.
            % This is accounted for by replacing the single number code
            % with nA and adding nB and nC as contact codes, where n is the
            % number provided.
            % We must also update the odes array to say whether these
            % contacts are anodes or cathodes.
            % This will also affect the percentages we calculated previously
            % since there will be a new number of anode and cathode contacts.
            three_in_one_codes = {'1','2','9','10'};
            % This includes the indices of the contact codes to 'expand'
            expand_these = find(ismember(cntct_codes,three_in_one_codes));
            num_cat = count(abbr,'-');
            num_an = count(abbr,'+');
            % Iterate through the contacts for which this operation needs
            % to be performed
            for i = 1:length(expand_these)
                act_all = cntct_codes{expand_these(i)};
                % Replace n with nA
                cntct_codes{expand_these(i)} = [act_all 'A'];
                % Append nB and nC
                cntct_codes{end+1} = [act_all 'B'];
                cntct_codes{end+1} = [act_all 'C'];
                odes(end+1) = odes(expand_these(i));
                odes(end+1) = odes(expand_these(i));
                if odes(expand_these(i)) == 1
                    num_cat = num_cat + 2;
                else
                    num_an = num_an + 2;
                end
            end
            % Adjust the even distribution of anode/cathode 
            % percentages among contacts
            percs = [100/num_cat 100/num_an];

            % Make sure the contact codes are valid for segmented leads
            % with medtronic's label convention
            cntct_allowed_codes={'C','0','3','1A','2A','1B','2B','1C','2C','8','11','9A','10A','9B','10B','9C','10C'};
            if ~all(cellfun(@(x) any(strcmp(x,cntct_allowed_codes)),cntct_codes))
                error(['AutoVAT parser: you specified seg and used a non-valid string for defining a contact' ...
                    ' in stimulation ' file{row,'stimulation'}{1}]);
            end

            % Iterate through the contact codes
            for i = 1:length(cntct_codes)
                
                % If the current code is for the case
                if strcmp(cntct_codes{i},case_code)
                    S.([sides(s) source]).case.pol = odes(i);
                    S.([sides(s) source]).case.perc = percs(odes(i));
                % If the current code isn't for the case
                else
                    % seg_lbl is 1 for A, 
                    % 2 for B, 
                    % 3 for C, or 
                    % 0 if there is no seg_lbl
                    [cntct_num,seg_lbl] = just_num(cntct_codes{i});

                    % Convert the medtronic label to the id of the
                    % contact to activate
                    cntct_id = -1;
                    switch mod(str2num(cntct_num),8)
                        % cntct_num 0 or 8  
                        case 0
                            cntct_id = cntct_num;
                        % cntct_num 1 or 9
                        case 1
                            cntct_id = num2str(str2num(cntct_num) + seg_lbl - 1);
                        % cntct_num 2 or 10
                        case 2
                            cntct_id = num2str(str2num(cntct_num) + seg_lbl + 1);
                        % cntct_num 3 or 11
                        case 3
                            cntct_id = num2str(str2num(cntct_num) + 4);
                    end
                    % Activate the contact
                    S.([sides(s) source]).([klit cntct_id]).pol = odes(i);
                    S.([sides(s) source]).([klit cntct_id]).perc = percs(odes(i));
                    S.([sides(s) source]).([klit cntct_id]).imp = nan;
                end
            end

        % If not segmented
        elseif strcmp(file{row,lead_type_col},'not_seg')
            % Check that the contact codes you have are valid for a
            % non-segmented lead of medtronic label convention
            cntct_allowed_codes={'0','1','2','3','C','8','9','10','11'};
            if ~all(cellfun(@(x) any(strcmp(x,cntct_allowed_codes)),cntct_codes))
                error(['AutoVAT parser: you specified not_seg and used a non-valid string for defining a contact' ...
                    ' in stimulation ' file{row,'stimulation'}{1}]);
            end
            % Iterate through the contact codes
            for i = 1:length(cntct_codes)
                % If you're activating the case
                if strcmp(cntct_codes{i},case_code)
                    S.([sides(s) source]).case.pol = odes(i);
                    S.([sides(s) source]).case.perc = percs(odes(i));
                % If you're activating a contact that's not a case
                else
                    S.([sides(s) source]).([klit cntct_codes{i}]).pol = odes(i);
                    S.([sides(s) source]).([klit cntct_codes{i}]).perc = percs(odes(i));
                    % Impedance is nan because this code is only written
                    % for current-controlled.  We thus do not care about
                    % impedance and want to ignore it.
                    S.([sides(s) source]).([klit cntct_codes{i}]).imp = nan;
                end
            end
        end
        % This is the processing that's common to both segmented and
        % non-segmented
        S = ft_common(S,file,row);
    else
        disp(['Error; electrode label convention not found ',file{row, lbl_conv_col}]);
    end
    
% Raw csv type
else
    % Made these into char arrays just so it's easier to modify
    on = 'on_';
    imp = 'imp_';
    cathode = 'cathode_';
    V = 'source_V_';
    R = 'R_';
    L = 'L_';
    c = 'c';
    slit = 's';
    src_str = '1';

    source_strlit = ['_source_' src_str];
    %% This program is written to only support source 1
    sstr = ([sides(1) slit src_str]);
    for k=0:7
        kstr = ([klit,num2str(k)]);
        S.(sstr).(kstr).perc=file{row,kstr};
        % If the contact is not specified as 'on', this will overrule
        % any other settings that have been specified
        S.(sstr).(kstr).pol= ...
            file{row,[on kstr]}*(file{row,[cathode kstr]}+1);
        % Impedance should be nan since this program is configured for
        % current-controlled and not voltage activated
        S.(sstr).(kstr).imp=file{row,[imp,kstr]};
    end
    sstr = ([sides(2) slit src_str]);
    for k=8:15
        kstr = ([klit,num2str(k)]);
        S.(sstr).(kstr).perc=file{row,kstr};
        % If the contact is not specified as 'on', this will overrule
        % any other settings that have been specified
        S.(sstr).(kstr).pol= ...
            file{row,[on kstr]}*(file{row,[cathode kstr]});
        % Impedance should be nan since this program is configured for
        % current-controlled and not voltage activated
        S.(sstr).(kstr).imp=file{row,[imp,kstr]};
    end
    for s = 1:size(sides,2)
        sstr = ([sides(s) slit src_str]);
        S.(sstr).amp=file{row,[sides(s) source_strlit]};
        % This program is not configured for volate activated so va
        % should be 0;
        S.(sstr).va=file{row,[sides(s) '_source_V_' src_str]};
        % Case should only be active on one side since this program
        % supports only unilateral stimulation
        S.(sstr).case.perc=file{row,[sides(s) '_' c]};
        S.(sstr).case.pol= ...
            file{row,[sides(s) '_' on c]} * file{row,[sides(s) '_' cathode c]};
    end
    % This processing is common to both raw and abbreviated file types  
    S = ft_common(S,file,row);
end 


function s = which_side(cntct_codes)
% Given the contact codes for a stimulation, determine whether the
% stimulation activates the left or right hemisphere
    s = 0;
    for i = 1:length(cntct_codes)
        % For any contact code that is not the case, you can see that the
        % stimulation activates the right hemisphere if any of the contact
        % numbers are less than 8, and it activates the left hemisphere
        % if any of the contact numbers are greater than or equal to 8
        if ~strcmp(cntct_codes{i}, 'C')
            cntct_num = just_num(cntct_codes{i});
            if str2num(cntct_num) < 8
                s = 1;
            else
                s = 2;
            end
            break
        end
    end

function [cntct_num,seg_lbl] = just_num(cntct_code)
% This takes a contact code - which is either a char array that is a number
% immediately followed by a character A, B, or C, or just a number.
% Ex. 10A, 11, 9, 0, 3, 2C, 7
% This returns the number portion of the char array as a char array (cntct_num)
% and an int denoting which letter followed the number (seg_lbl):
% 0 for no letter, 1 for A, 2 for B, and 3 for C
    cntct_num = cntct_code;
    seg_lbls = 'ABC';
    seg_lbl = 0;
    if ismember(cntct_num(end),seg_lbls)
        seg_lbl = strfind(seg_lbls,cntct_num(end));
        cntct_num = cntct_num(1:end-1);
    end

function S = ft_common(S,file,row)
% This function performs the stimulation construction that is common to
% both csv types: abbreviated and raw.
%% I'm not really sure what effect r_active and l_active have;
% they don't seem to make a difference, but I set them to what they should
% be anyways.  Since this program is only configured to activate either one
% hemisphere or the other, you only need to know r_active to tell l_active

    S.label = file{row,'stimulation'}{1};
    S.model = file{row, 'model'}{1};

    monopolar_models = ['Maedler 2012' 'Kuncel 2008' 'Dembek 2017'];
    if ismember(S.model,monopolar_models)
        S.monopolarmodel = 1;
    else
        S.monopolarmodel = 0;
    end
    
    % 1x2 array showing which source is active on which hemisphere (I think)
    % Both are automatically set to 1 here because this program only
    % supports activation of source 1 in either hemisphere
    % First entry should be right hemisphere, second should be left
    % Since the code only stimulates one hemisphere at a time, I would set
    % whichever hemisphere is inactive to 0, but lead dbs doesn't like that
    % and breaks if I do.
    S.active=[1 1];
    % 2x4 reiteration of the source amplitudes already given
    S.amplitude={[S.Rs1.amp, S.Rs2.amp,S.Rs3.amp,S.Rs4.amp]...
                        [S.Ls1.amp, S.Ls2.amp,S.Ls3.amp,S.Ls4.amp]};
    % ea_activecontacts just takes care of this
    S=ea_activecontacts(S);

function S = empty_S()
% Initialize empty S as exactly copied from ea_initializeS but without
% using options and handles

    % right sources
    for source=1:4
        for k=0:7
            eval(['S.Rs',num2str(source),'.k',num2str(k),'.perc=0;']);
            eval(['S.Rs',num2str(source),'.k',num2str(k),'.pol=0;']);
            eval(['S.Rs',num2str(source),'.k',num2str(k),'.imp=1;']);
        end
        eval(['S.Rs',num2str(source),'.amp=0;']);
        eval(['S.Rs',num2str(source),'.va=1;']);
        eval(['S.Rs',num2str(source),'.case.perc=0;']);
        eval(['S.Rs',num2str(source),'.case.pol=0;']);
    end
    
    % left sources
    for source=1:4
        for k=8:15
            eval(['S.Ls',num2str(source),'.k',num2str(k),'.perc=0;']);
            eval(['S.Ls',num2str(source),'.k',num2str(k),'.pol=0;']);
            eval(['S.Ls',num2str(source),'.k',num2str(k),'.imp=1;']);
        end
        eval(['S.Ls',num2str(source),'.amp=0;']);
        eval(['S.Ls',num2str(source),'.va=1;']);
        eval(['S.Ls',num2str(source),'.case.perc=0;']);
        eval(['S.Ls',num2str(source),'.case.pol=0;']);
    end
    
    S.active=[1,1];
    S.model='SimBio/FieldTrip (see Horn 2017)';
    S.monopolarmodel=0;
    S.amplitude={[0,0,0,0],[0,0,0,0]};
    S=ea_activecontacts(S);