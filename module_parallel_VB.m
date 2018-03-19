function [this_SPM_block] = module_parallel_VB(z)

this_block = z;
load('temp_estimate/pre_estimate_workspace.mat');
z = this_block;

%-Print progress information in command window
%-------------------------------------------------------------------
str   = sprintf('Block %3d/%-3d',z,nLb);
fprintf('\r%-40s: %30s',str,' ')                                %-#

%-Construct list of voxels
%-------------------------------------------------------------------
Q           = find(Lb==z);
[xx,yy,zz]  = ind2sub(size(mask),Q);
xyz         = [xx,yy,zz]';                      %-voxel coordinates
nVox        = size(xyz,2);

%-Get data
%-------------------------------------------------------------------
fprintf('%s%30s\n',repmat(sprintf('\b'),1,30),'...read & mask data');%-#

Y     = zeros(nScan,nVox);
for i = 1:nScan
    
    Y(i,:)  = spm_get_data(VY(i),xyz);
    
end

vxyz = spm_vb_neighbors(xyz',vol);

%-Conditional estimates (per partition, per voxel)
%-------------------------------------------------------------------
beta  = zeros(nBeta,nVox);
Psd   = zeros(nPsd, nVox);
LogEv = zeros(1,nVox);

for s=1:nsess
    Sess(s).Hp = zeros(1, nVox);
    Sess(s).AR = zeros(SPM.PPM.AR_P, nVox);
end

if ncon > 0
    con     = zeros(ncon,nVox);
    con_var = zeros(ncon,nVox);
end

%-Get structural info for that block
%-------------------------------------------------------------------
if strcmp(SPM.PPM.priors.A,'Discrete')
    sxyz = xDiscrete(1).mat\M*[xyz;ones(1,nVox)];
    gamma = [];
    for j=1:SPM.PPM.priors.Sin
        gamma(:,j) = spm_get_data(xDiscrete(j),sxyz)';
    end
    if SPM.PPM.priors.Sin==1
        unaccounted=find(gamma==0);
        if length(unaccounted) > 0
            % Create extra category
            SPM.PPM.priors.S=2;
            gamma(:,2)=zeros(nVox,1);
            gamma(unaccounted,2)=1;
            gamma(:,1)=ones(nVox,1)-gamma(:,2);
            SPM.PPM.priors.gamma=gamma;
        else
            SPM.PPM.priors.S=1;
            SPM.PPM.priors.gamma=ones(nVox,1);
        end
    else
        unaccounted=find(sum(gamma')==0);
        if length(unaccounted)>0
            % Create extra category
            SPM.PPM.priors.S=SPM.PPM.priors.Sin+1;
            gamma(:,SPM.PPM.priors.S)=zeros(1,nVox);
            gamma(unaccounted,SPM.PPM.priors.S)=1;
        else
            SPM.PPM.priors.S=SPM.PPM.priors.Sin;
        end
        % convert probabilities to discrete values
        SPM.PPM.priors.gamma=zeros(nVox,SPM.PPM.priors.S);
        [yy,ii]=max(gamma');
        for j=1:SPM.PPM.priors.S
            SPM.PPM.priors.gamma(find(ii==j),j)=1;
        end
    end
end

%-Estimate model for each session separately
%-------------------------------------------------------------------
for s = 1:nsess
    
    fprintf('Session %d',s);                                %-#
    block = block_template(s);
    block = spm_vb_set_priors(block,SPM.PPM.priors,vxyz);
    
    %-Filter data to remove low frequencies
    %---------------------------------------------------------------
    R0Y = hpf(s).R0*Y(SPM.Sess(s).row,:);
    
    %-Fit model
    %---------------------------------------------------------------
    switch SPM.PPM.priors.A
        case 'Robust',
            %k=SPM.PPM.priors.k;
            block = spm_vb_robust(R0Y,block);
        otherwise
            block = spm_vb_glmar(R0Y,block);
    end
    
    %-Report AR values
    %---------------------------------------------------------------
    if SPM.PPM.AR_P > 0
        % session specific
        Sess(s).AR(1:SPM.PPM.AR_P,:) = block.ap_mean;
    end
    
    if SPM.PPM.update_F
        switch SPM.PPM.priors.A
            case 'Robust',
                Fn=block.F;
                SPM.PPM.Sess(s).block(z).F=sum(Fn);
            otherwise
                SPM.PPM.Sess(s).block(z).F = block.F;
                % Contribution map sums over sessions
                Fn = spm_vb_Fn(R0Y,block);
        end
        LogEv = LogEv+Fn;
    end
    
    %-Update regression coefficients
    %---------------------------------------------------------------
    ncols=length(SPM.Sess(s).col);
    beta(SPM.Sess(s).col,:) = block.wk_mean(1:ncols,:);
    if ncols==0
        % Design matrix empty except for constant
        mean_col_index=s;
    else
        mean_col_index=SPM.Sess(nsess).col(end)+s;
    end
    beta(mean_col_index,:) = block.wk_mean(ncols+1,:); % Session mean
    
    %-Report session-specific noise variances
    %---------------------------------------------------------------
    Sess(s).Hp(1,:)        = sqrt(1./block.mean_lambda');
    
    %-Store regression coefficient posterior standard deviations
    %---------------------------------------------------------------
    Psd (SPM.Sess(s).col,:) = block.w_dev(1:ncols,:);
    Psd (mean_col_index,:) = block.w_dev(ncols+1,:);
    
    %-Update contrast variance
    %---------------------------------------------------------------
    if ncon > 0
        for ic=1:ncon,
            CC=SPM.xCon(ic).c;
            % Get relevant columns of contrast
            CC=[CC(SPM.Sess(s).col) ; 0];
            for i=1:nVox,
                con_var(ic,i)=con_var(ic,i)+CC'*block.w_cov{i}*CC;
            end
        end
    end
    
    switch SPM.PPM.priors.A,
        case 'Robust',
            % Save voxel data where robust model is favoured
            outlier_voxels=find(Fn>0);
            N_outliers=length(outlier_voxels);
            Y_out=R0Y(:,outlier_voxels);
            gamma_out=block.gamma(:,outlier_voxels);
            analysed_xyz=xyz;
            outlier_xyz=analysed_xyz(:,outlier_voxels);
            
            SPM.PPM.Sess(s).block(z).outlier_voxels=outlier_voxels;
            SPM.PPM.Sess(s).block(z).N_outliers=N_outliers;
            SPM.PPM.Sess(s).block(z).Y_out=Y_out;
            SPM.PPM.Sess(s).block(z).gamma_out=gamma_out;
            SPM.PPM.Sess(s).block(z).outlier_xyz=outlier_xyz;
            
            block = spm_vb_taylor_R(R0Y,block);
            SPM.PPM.Sess(s).block(z).mean=block.mean;
            SPM.PPM.Sess(s).block(z).N=block.N;
            
            % Prior precision
            SPM.PPM.Sess(s).block(z).mean_alpha=block.mean_alpha;
            
        otherwise
            % Prior precision
            SPM.PPM.Sess(s).block(z).mean_alpha=block.mean_alpha;
            
            %-Get block-wise Taylor approximation to posterior correlation
            %-------------------------------------------------------
            block = spm_vb_taylor_R(R0Y,block);
            SPM.PPM.Sess(s).block(z).mean=block.mean;
            SPM.PPM.Sess(s).block(z).elapsed_seconds=block.elapsed_seconds;
            
            %-Save Coefficient RESELS and number of voxels
            %-------------------------------------------------------
            SPM.PPM.Sess(s).block(z).gamma_tot=block.gamma_tot;
            SPM.PPM.Sess(s).block(z).N=block.N;
    end
    
    %-Save typical structure-specific AR coeffs
    %---------------------------------------------------------------
    if strcmp(SPM.PPM.priors.A,'Discrete')
        SPM.PPM.Sess(s).block(z).as_mean=block.as;
        SPM.PPM.Sess(s).block(z).as_dev=sqrt(1./block.mean_beta);
    end
    
    clear block;
end % loop over sessions


this_SPM_block = SPM;
save(['temp_estimate/SPM_PPM_' num2str(z) '.mat'], 'SPM','beta','Psd','LogEv','Sess')
