%A short script for opening fslview and looking at an image file

function fslview(imagefile)

fsldir = '/imaging/local/software/fsl/fsl64/fsl-5.0.3/fsl';

setenv('FSLDIR',fsldir);  % this to tell where FSL folder is
setenv('FSLOUTPUTTYPE', 'NIFTI'); % this to tell what the output type

cmd = [fsldir '/bin/fslview ' imagefile];

system(cmd)