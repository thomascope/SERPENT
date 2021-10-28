function Q = calc_tsnr(P)
% Calculate temporal signal to noise ratio for volumes in P
% FORMAT Q = calc_tsnr(P)
% INPUT
% P       - functional image filenames, either 
%           1: character array or cell array of strings
%           2: SPM structure
% OUTPUT
% Q       - Image(s) with voxel values mean / SD of input images
%
% Does not include any implicit masking
% PW 25/03/2012

% What is P?
if isstruct(P)
    if isfield(P,'Sess')
        nsess = length(P.Sess);
        for sess = 1:nsess
            rowind = P.Sess(sess).row;
            thisP = P.xY.P(rowind);
            [p n e] = spm_fileparts(P(1,:));
            thisfilename = fullfile(p,sprintf('tsnr_sess%d',sess));
			if sess == 1
				Q = docalc(thisP,thisfilename);
			else
				Q = strvcat(Q,docalc(thisP,thisfilename));
			end
        end
    else
        error('Input variable is a structure, but does not have field Sess, so it probably is not a valid SPM structure')
    end
elseif iscellstr(P)
    P = char(P);
    [p n e] = spm_fileparts(P(1,:));
    filename = fullfile(p,'tsnr.nii');
    Q = docalc(P,filename);
elseif ischar(P)
    [p n e] = spm_fileparts(P(1,:));
    filename = fullfile(p,'tsnr.nii');
    Q = docalc(P,filename);
else
    error('Could not figure out input variable P')
end

% Everything else is handled by the subfunction docalc
end

function Q = docalc(P,filename)
V = spm_vol(P);
Vo = V(1);
Vo.fname = filename;
Vo = spm_imcalc(V,Vo,'mean(X) ./ std(X)',{1 0 0});
Q = Vo.fname;
end


