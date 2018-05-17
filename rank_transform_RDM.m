function thisRDM = rank_transform_RDM(RDMs,figI,rankTransform01,clims,showColorbar, aspect, imagelabels, colourScheme)
% visualizes one or many RDMs. RDMs is a structure of RDMs (wrapped RDMs).
% The 'RDM' and 'name' subfileds are required for this function only. figI
% is the figure number in which the RDMs are displayed. if rankTransform01
% is defined, the dissimilarities would be rankTransformed before
% visualization. clims is a 1x2 vector specfying the lower and upper limits
% for displayed dissimilarities. if showColorbar is set, the colorbar would
% also be displayed in a separate panel. aspect: number of horizontal
% panels/number of vertical panels. colourScheme: the colour scheme for
% displaying dissimilarities (defined by RDMcolormap by default). 
% imagelabels: a structure containg the RGB values for images that would be
% displayed on an RDM. 
% CW: 5-2010, 7-2010. HN: 9-2013
%__________________________________________________________________________
% Copyright (C) 2010 Medical Research Council

%% define default behavior
if ~exist('figI','var'), figI=500; end
if ~exist('clims','var'), clims=[]; end
if ~exist('rankTransform01','var'), rankTransform01=true; clims=[0 1]; end
if ~exist('showColorbar','var'), showColorbar=true; end
if ~exist('aspect', 'var') || isempty(aspect), aspect = 2/3; end

%% handle RDM types

colourScheme = RDMcolormap;
if isstruct(RDMs)
	[rawRDMs nRDMs] = unwrapRDMs(RDMs);
else
	rawRDMs = RDMs;
	nRDMs = size(rawRDMs, 3);
end%if:isstruct(RDMs)

% rawRDMs is now [nC nC nR] or [1 t(nC) nR]

cellRDMs = cell(1, nRDMs);

allMin = inf;
allMax = -inf;

for RDMi = 1:nRDMs

	thisRDM = rawRDMs(:, :, RDMi);

	if max(size(thisRDM)) == numel(thisRDM)
		% Then it's in ltv form
		% So we've got a symmetric RDM
		% Square it
		thisRDM = squareform(thisRDM); % squareform leaves 0s on the diagonal, which is what we want
		RDMtype{RDMi} = '';
	else
		% Then it's a square RDM
		if isequalwithequalnans(thisRDM, thisRDM')
			% It's symmetric
			if ~any(diag(thisRDM)) && ~any(isnan(diag(thisRDM))) % 0s on the diagonal
				% It's a regular RDM
				RDMtype{RDMi} = '';
			elseif isnan(thisRDM(1,1)) % (1,1) is a nan
				% It's a very lucky cv2RDM
				RDMtype{RDMi} = '[cv2RDM] ';
			else
				% symmetric, not all 0s or all nans on diagonal
				warning(['RDM ' num2str(RDMi) ' is symmetric, but has neither all 0s or all NaNs on the diagonal.  Not sure how to deal with this.']);
                RDMtype{RDMi} = '[anomalous diag.] '
			end
		else
			% It's not symmetric
			if isnan(thisRDM(1,1)) % (1,1) is a nan
				% It's a cv2RDM
				RDMtype{RDMi} = '[cv2RDM] ';
			else
				% It's a sdRDM
				RDMtype{RDMi} = '[sdRDM] ';
			end
		end
	end

	% Work out extreme values
	offDiagonalEntries = thisRDM(eye(size(thisRDM, 1))==0);
	thisMin = nanmin(offDiagonalEntries);
	thisMax = nanmax(offDiagonalEntries);

	allMin = min(allMin, thisMin);
	allMax = max(allMax, thisMax);

	cellRDMs{1,RDMi} = thisRDM;

end%for:RDMi

% cellRDMs is now a [1 nRDMs]-sized cell of square RDMs (of various kinds and sizes)

if isempty(clims)
	clims = [allMin allMax];
end%if:clims

%% normalise dissimilarity matrices
    
for RDMi=1:nRDMs

	thisRDM = cellRDMs{RDMi};

	% Determine alpha data to make nans invisible
	alpha = ~isnan(thisRDM);

	if rankTransform01
		thisRDM = scale01(rankTransform_equalsStayEqual(thisRDM,1));
	end
			
end

