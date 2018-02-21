% Function written by Simon Jones to dilate a binary mask
% If no kernel is specified, dilates by 10mm

function dilate_image_spm(p,kernel,suffix)


%%Dilate a 3D image p by kernel mm to make binary mask

 

spm('defaults','pet');

 

% kernel(:,:,1) = [ 0 0 0; 0 1 0; 0 0 0];

% kernel(:,:,2) = [ 0 1 0; 1 1 1; 0 1 0];

% kernel(:,:,3) = [ 0 0 0; 0 1 0; 0 0 0];

 

if nargin<1

    p=spm_select(1,'image','Select Image to dilate');

end

 

if nargin<2

    kernel=10;

end


if nargin<3

    suffix='';

end

 

vi=spm_vol(p);

yi=spm_read_vols(vi);

 

%Use average voxel size

meanvmm=power(abs(det(vi.mat)),1/3);

kernel=kernel/meanvmm;

if ~mod(kernel,2)

    kernel= kernel+1;

end

 

% se = strel('ball',kernel,kernel);

 

[x,y,z] = ndgrid(-kernel:kernel);

se = strel(sqrt(x.^2 + y.^2 + z.^2) <=kernel);

 

vo=vi;

[apath,aname,anext]=fileparts(vi.fname);

outname=strcat(aname,suffix);

vo.fname=fullfile(apath,strcat(outname,anext));

vo=spm_create_vol(vo);

%yo=spm_dilate(yi,kernel);

 

yo=imdilate(single(yi),se); 

yo=(yo-min(yo(:)))/(max(yo(:))-min(yo(:)));

yo=yo>0;

 

for k=1:size(yi,3)

    vo=spm_write_plane(vo,yo(:,:,k),k);

end

 

disp('Finshed dilation')

 