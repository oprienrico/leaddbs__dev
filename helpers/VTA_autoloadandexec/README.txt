This program allows the user to run multiple simulations back-to-back by providing a csv file with the stimulation
parameters.

The user runs lead dbs as they normally would until they reach the magic wand stimulate button.  After clicking
this button, lead dbs will request a name for the stimulation which the user must provide to move forward as per
usual.  However, if the user intends to run this program and generate stimulations from a csv, this name will be
ignored.  Instead, lead dbs will use the names provided for each individual stimulation in the csv.  This request
for a stimulation name will not appear if there are saved stimulation that lead dbs will load up from the
patient's stimulation subdirectory.

When the stimulation parameter window subsequently appears after providing a stimulation name, the user will now 
see a text input box and a checkbox at the top of the window.  The user will provide the path of the csv file in 
the text input box, and must also check the checkbox to indicate that lead dbs should use this file instead of
any parameters entered in the window.  Once the filepath is provided and the checkbox is checked, the user will
be able to press the visualize button at the bottom of the window to run their stimulations.  These stimulations
will be saved in the same stimulation patient subdirectory that the stimulations are typically stored in.

After running the stimulations, the user can close and reopen the stimulation parameter window to find that they
can load their stimulations from the dropdown menu, which will now contain the names of the stimulations from
the csv file.  Disregard how the unstimulated hemisphere does automatically sets K1/K9 to cathode and Case to 
anode; this should not have any effect with a non-zero source and no activation percentage specified.  It looks
like it's simply a side effect of the lead dbs gui. 
To clear the dropdown menu of stimulations you've already run, delete the stimulation folders from the patient
subdirectory (the folders will have the names given to the stimulations by the user).  Try clearing these folders,
exiting the stim param window, and starting again by clicking the magic wand button if you run into issues.

This program only supports the current-controlled activation of the first source on one side at a time:
it will not run stimulations on both hemispheres simultaneously.  This program also assumes that the percentage
will be evenly distributed among the cathode and anode contacts: for example, if C, 1A, and 1B are all set to
cathode, and 3 is set to be an anode, the activation percentages of C, 1A, and 1B will all be 33.33, and the
activation percentage of contact 3 will be 100.

The csv files must be arranged in one of two ways: raw or abbreviated.  Raw refers to the csv type where each
stimulation parameter is defined in its own cell.  Abbreviated refers to the csv type where a contact activation
is specified in an abbreviated form.  Ensure that the file is truly of csv type: you should be able to open it in 
Notepad and see a legible, comma-separated list.  Renaming an Excel file extension to csv is not typically
sufficient.  These csvs will be read into the MatLab code as a table.

The csvs should be organized as follows:

Raw
STILL BUGGY: DEVELOPMENT NOT COMPLETE BECAUSE USAGE NOT EXPECTED
The column names should each have their own cell in the very first row of the csv.
Thus the first row should be identical to this:
stimulation,model,R_source_V_1,R_source_1,L_source_V_1,L_source_1,on_k0,cathode_k0,k0,imp_k0,on_k1,cathode_k1,k1,imp_k1,on_k2,cathode_k2,k2,imp_k2,on_k3,cathode_k3,k3,imp_k3,on_k4,cathode_k4,k4,imp_k4,on_k5,cathode_k5,k5,imp_k5,on_k6,cathode_k6,k6,imp_k6,on_k7,cathode_k7,k7,imp_k7,R_on_c,R_cathode_c,R_c,on_k8,cathode_k8,k8,imp_k8,on_k9,cathode_k9,k9,imp_k9,on_k10,cathode_k10,k10,imp_k10,on_k11,cathode_k11,k11,imp_k11,on_k12,cathode_k12,k12,imp_k12,on_k13,cathode_k13,k13,imp_k13,on_k14,cathode_k14,k14,imp_k14,on_k15,cathode_k15,k15,imp_k15,L_on_c,L_cathode_c,L_c
You can see why we made an abbreviated form :)
The columns specify the following: 
stimulation - the name of the stimulation, the user is free to choose this.  Running this program with the name of
an already saved stimulation will overwrite the saved stimulation.
model - one of six options, which must be copied exactly (identical to abbreviated csv type):
Dembek 2017, Fastfield (Baniasadi 2020), Kuncel 2008, Maedler 2012, SimBio/FieldTrip (see Horn 2017), and
OSS-DBS (Butenko 2020)
R/L_source_V_1 - whether the right/left source is voltage activated.  Should be set to 0
R/L_source_1 - how much current should be applied to the rought/left source 1.  Uses the same units as the
stimulation window parameters
on_kn - whether contact with id n should be active
cathode_kn - 0 for not active, 1 to specify cathode, 2 to specify anode
kn - specifies the percentage of activation for this contact.  Possible range is 0 to 100.  The sum of all
the cathode contact percentage activations should be 100, and the sum of all the anode contact percentage
activations should also be 100
imp_kn - impedance of contact n; should always be set to nan since this program only supports current-activated.
Default is 1 for non-active contacts.
R/L_on_c - whether the case should be activated for the right/left hemisphere
R/L_cathode_c - 0 for not active, 1 to specify cathode, 2 to specify anode
R/L_c - specifies the relative percentage of activation for the case.  Possible range is 0 to 100.  The sum of all
the cathode contact percentage activations should be 100, and the sum of all the anode contact percentage
activations should also be 100

Abbreviated
The column names should each have their own cell in the very first row of the csv.
Thus the first row should be identical to this:
stimulation,model,lbl_convention,lead_type,contact_lbl,amp
The columns specify the following: 
stimulation - the name of the stimulation, the user is free to choose this.  Running this program with the name of
an already saved stimulation will overwrite the saved stimulation.
model - one of six options which must be copied exactly (identical to raw csv type):
Dembek 2017, Fastfield (Baniasadi 2020), Kuncel 2008, Maedler 2012, SimBio/FieldTrip (see Horn 2017), and
OSS-DBS (Butenko 2020)
lbl_convention - must be specified exactly as medtronic since this program only supports medtronic's label
convention
lead_type - either seg for segmented or not_seg for not segmented
contact_lbl - specified which contacts should be activated and whether they should be anodes or cathodes.  Each
contact code must be followed by a + (to specify anode) or minus (to specify cathode). At least one anode and at
least one cathode must be specified.  C stands for case.
seg ex. C+1B-2C+	3+1-
In the latter example, 1A, 1B, and 1C will each be activated at 33.3% as cathodes since 1 is a segmented contact.
not_seg ex. 3-C+2+	8+9+10+11-
In the former example, contact two will be activated at 50% as an anode since it is not a segmented contact.

for segmented leads		lead_type=="seg"							
kontact			0	1	2	3	4	5	6	7
medtronic lbl		0	1A	1B	1C	2A	2B	2C	3
										
kontact			8	9	10	11	12	13	14	15
medtronic lbl		8	9A	9B	9C	10A	10B	10C	11
									
for cilindrical (3389)		lead_type=="not_seg"							
kontact			0	1	2	3	4	5	6	7
medtronic lbl		0	1	2	3	NAN	NAN	NAN	NAN
kontact			8	9	10	11	12	13	14	15
medtronic lbl		8	9	10	11	NAN	NAN	NAN	NAN


Testing
RAW CSV TYPE STILL BUGGY: DEVELOPMENT NOT COMPLETE BECAUSE USAGE NOT EXPECTED
Ran the not_seg abbreviated test with a Medtronic 3389 lead dbs setting.  Only works for Fastfield and Horn models
Ran the seg abbreviated test with a Boston Vericise Directed lead dbs setting.  Only works for Fastfield model