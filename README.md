LEAD-DBS bleeding edge
========

LEAD-DBS is ***NOT*** intended for clinical use!

## Notes (and how to use it)
This version is intended to test out all the pull requests I am working on, before they are pushed to the mainline LEAD-DBS
If you want to use test these features/bugfixes before they go to the mainline, download it and do NOT keep it up to date though GIT.

This is just because it this branch will be deleted and regenerated after every pull-request have been processed. 
Hence, it will not have a clean git-history and will mismatch with your local history.


## About Lead-DBS

LEAD-DBS is a MATLAB toolbox facilitating the:

- reconstruction of deep-brain-stimulation (DBS) electrodes in the human brain on basis of postoperative MRI and/or CT imaging
- the visualization of localization results in 2D/3D
- a group-analysis of DBS-electrode placement results and their effects on clinical results
- simulation of DBS stimulations (calculation of volume of activated tissue – VAT)
- diffusion tensor imaging (DTI) based connectivity estimates and fiber-tracking from the VAT to other brain regions (connectomic surgery)

## Installation

#### Prerequisites

- Recommended RAM size: 16GB or more
- MATLAB version: R2017b (MATLAB 9.3) or later
- MATLAB Image Processing Toolbox
- MATLAB Signal Processing Toolbox
- SPM12

#### Normal installation

Lead-DBS can be downloaded from our website (www.lead-dbs.org) in fully functional form.

#### Development installation

Alternatively, especially in case you wish to modify and contribute to Lead-DBS, you can

- Clone the Lead-DBS repository from [github](https://github.com/netstim/leaddbs.git).
- Download the necessary [data](http://www.lead-dbs.org/release/download.php?id=data_pcloud) and unzip it into the cloned git repository.

We’d love to implement your improvements into Lead-DBS – please contact us for direct push access to Github or feel free to add pull-requests to the Lead-DBS repository.

## Getting started

You can run Lead-DBS by typing "lead demo" into the Matlab prompt. This will open up the main GUI and a 3D viewer with an example patient.
But there's much more to explore. Head over to https://www.lead-dbs.org/ to see a walkthrough tutorial, a manual, some more screenshots and other ressources. There's also a helpline in form of a Slack channel. We would love to hear from you.

## Questions

If you have questions/problems when using Lead-DBS, you can checkout our:

- Online [manual](https://netstim.gitbook.io/leaddbs/)
- Workthrough [videos](https://www.lead-dbs.org/helpsupport/knowledge-base/walkthrough-videos/)
- Knowledge [base](https://www.lead-dbs.org/helpsupport/knowledge-base/) (including [methods](https://www.lead-dbs.org/helpsupport/knowledge-base/lead-dbs-methods/), [cortical](https://www.lead-dbs.org/helpsupport/knowledge-base/atlasesresources/cortical-atlas-parcellations-mni-space/)/[subcortical](https://www.lead-dbs.org/helpsupport/knowledge-base/atlasesresources/atlases/) atlases, [connectomes](https://www.lead-dbs.org/helpsupport/knowledge-base/atlasesresources/normative-connectomes/), etc.)
- Support [forum](https://www.lead-dbs.org/?forum=lead-dbs-support-forum)
- [Auto-invite](https://leadsuite.herokuapp.com/) Slack [workspace](https://leadsuite.slack.com/)
