% script to convert MP2RAGE images into T1 (R1) map estimates as suggested in:
% MP2RAGE, a self bias-field corrected sequence for improved segmentation and T 1-mapping at high field
% JP Marques, T Kober, G Krueger, W van der Zwaag, PF Van de Moortele, R.
% Gruetter, Neuroimage 49 (2), 1271-1281, 2010
%
%
%
% addpath(genpath('.'))
%% MP2RAGE protocol info and loading the MP2RAGE dataset 
MP2RAGE.B0=7;% in Tesla
MP2RAGE.TR=6;% MP2RAGE TR in seconds 
MP2RAGE.TRFLASH=6.7e-3;% TR of the GRE readout
MP2RAGE.TIs=[800e-3 2700e-3];% inversion times - time between middle of refocusing pulse and excitatoin of the k-space center encoding
MP2RAGE.NZslices=[35 72];% Slices Per Slab * [PartialFourierInSlice-0.5  0.5]
MP2RAGE.FlipDegrees=[4 5];% Flip angle of the two readouts in degrees
MP2RAGE.filename='D:\OneDrive - University Of Cambridge\work\spm\toolbox\mp2rage_scripts\data\psj\MP2RAGE_UNI.nii';
MP2RAGE.filenameOUT='D:\OneDrive - University Of Cambridge\work\spm\toolbox\mp2rage_scripts\data\psj\MP2RAGE_UNI.nii';
% check the properties of this MP2RAGE protocol... this happens to be a
% very B1 insensitive protocol

plotMP2RAGEproperties(MP2RAGE);
% load the MP2RAGE data - it can be either the SIEMENS one scaled from
% 0 4095 or the standard -0.5 to 0.5
MP2RAGEimg=load_untouch_nii(MP2RAGE.filename);
[T1map, R1map]=T1estimateMP2RAGE(MP2RAGEimg,MP2RAGE,0.96);    
disp('Finished')

%% Saving data if that is the case
% if isfield(MP2RAGE, 'filenameOUT')
%     if ~isempty(MP2RAGE.filenameOUT)
% %         disp(['Saving: ' MP2RAGE.filenameOUT])
%         if integerformat==0
MP2RAGEimg.hdr.dime.datatype=16;
MP2RAGEimg.hdr.dime.bitpix=32;
MP2RAGEimg.img = round(4095*(T1map + 0.5));
save_untouch_nii(MP2RAGEimg, MP2RAGE.filenameOUT);
%         else
%             MP2RAGEimg.img = round(4095*(MP2RAGEimgRobustPhaseSensitive + 0.5));
%             save_untouch_nii(MP2RAGEimg, MP2RAGE.filenameOUT);
%         end
%     end
% end