function module_create_json(rawfilePath,outfilePath)
% A function for making JSON files from dicom headers to make everything
% into BIDS format

%read from here
rawfile_dcmhdr = strsplit(rawfilePath,'.nii');
rawfile_dcmhdr = rawfile_dcmhdr{1};
rawfile_dcmhdr = [rawfile_dcmhdr '.dcmhdr'];
rawfile_stimes = [rawfile_dcmhdr '.stimes'];

%write to here
outfile_json = strsplit(outfilePath,'.nii');
outfile_json = outfile_json{1};
outfile_json = [outfile_json '.json'];

outfile_dir = fileparts(outfilePath);

%read in dicomfile as a reference
dcm_text_id = fopen(rawfile_dcmhdr);
dcm_text = textscan(dcm_text_id,'%s','delimiter','\n');
fclose(dcm_text_id);

% dcm_text = textscan(rawfile_dcmhdr);
% TextAsCells = regexp(dcm_text, '\n', 'split');
TextAsCells = dcm_text{1};

%open file for writing
fileID = fopen(outfile_json,'w');

%Preamble
fprintf(fileID,'{\n');

%Line by Line construction
try
    Modality = read_this_dicom_line('Modality',TextAsCells);
    fprintf(fileID,['  "Modality": "' Modality '",\n']);
end
try
    MagneticFieldStrength = read_this_dicom_line('Magnetic Field Strength',TextAsCells);
    MagneticFieldStrength = num2str(round(str2num(MagneticFieldStrength))); %Round 6.98 to 7
    fprintf(fileID,['  "MagneticFieldStrength": ' MagneticFieldStrength ',\n']);
end
try
    ImagingFrequency = read_this_dicom_line('Imaging Frequency',TextAsCells);
    fprintf(fileID,['  "ImagingFrequency": ' ImagingFrequency ',\n']);
end
try
    Manufacturer = read_this_dicom_line('Manufacturer',TextAsCells);
    fprintf(fileID,['  "Manufacturer": "' Manufacturer '",\n']);
end
try
    ManufacturersModelName = read_this_dicom_line('Manufacturer''s Model Name',TextAsCells);
    fprintf(fileID,['  "ManufacturersModelName": "' ManufacturersModelName '",\n']);
end
try
    InstitutionName = read_this_dicom_line('Institution Name',TextAsCells);
    fprintf(fileID,['  "InstitutionName": "' InstitutionName '",\n']);
    fprintf(fileID,['  "InstitutionalDepartmentName": "' InstitutionName '",\n']);
end
try
    InstitutionAddress = read_this_dicom_line('Institution Address',TextAsCells);
    fprintf(fileID,['  "InstitutionAddress": "' InstitutionAddress '",\n']);
end
try
    DeviceSerialNumber = read_this_dicom_line('Device Serial Number',TextAsCells);
    fprintf(fileID,['  "DeviceSerialNumber": "' DeviceSerialNumber '",\n']);
end
try
    StationName = read_this_dicom_line('Station Name',TextAsCells);
    fprintf(fileID,['  "StationName": "' StationName '",\n']);
end
try
    BodyPartExamined = read_this_dicom_line('BodyPartExamined',TextAsCells);
    fprintf(fileID,['  "Body Part Examined": "' BodyPartExamined '",\n']);
end
try
    PatientPosition = read_this_dicom_line('Patient Position',TextAsCells);
    fprintf(fileID,['  "PatientPosition": "' PatientPosition '",\n']);
end
try
    ProcedureStepDescription = read_this_dicom_line('Performed Procedure Step Descriptio',TextAsCells);
    fprintf(fileID,['  "ProcedureStepDescription": "' ProcedureStepDescription '",\n']);
end
try
    SoftwareVersions = read_this_dicom_line('Software Version(s)',TextAsCells);
    fprintf(fileID,['  "SoftwareVersions": "' SoftwareVersions '",\n']);
end
try
    MRAcquisitionType = read_this_dicom_line('MR Acquisition Type',TextAsCells);
    fprintf(fileID,['  "MRAcquisitionType": "' MRAcquisitionType '",\n']);
end
try
    SeriesDescription = read_this_dicom_line('Series Description',TextAsCells);
    fprintf(fileID,['  "SeriesDescription": "' SeriesDescription '",\n']);
end
try
    ProtocolName = read_this_dicom_line('Protocol Name',TextAsCells);
    fprintf(fileID,['  "ProtocolName": "' ProtocolName '",\n']);
end
try
    ScanningSequence = read_this_dicom_line('Scanning Sequence',TextAsCells);
    fprintf(fileID,['  "ScanningSequence": "' ScanningSequence '",\n']);end
try
    SequenceVariant = read_this_dicom_slashed_line('Sequence Variant',TextAsCells);
    fprintf(fileID,['  "SequenceVariant": [\n']); 
    for i = 1:length(SequenceVariant)-1
        fprintf(fileID,['    "' deblank(SequenceVariant{i}) '",\n']);
    end
    fprintf(fileID,['    "' deblank(SequenceVariant{end}) '"\n']);
    fprintf(fileID,['  ],\n']);
end
try
    ScanOptions = read_this_dicom_slashed_line('Scan Options',TextAsCells);
    fprintf(fileID,['  "ScanOptions": [\n']); 
    for i = 1:length(ScanOptions)-1
        fprintf(fileID,['    "' deblank(ScanOptions{i}) '",\n']);
    end
    fprintf(fileID,['    "' deblank(ScanOptions{end}) '"\n']);
    fprintf(fileID,['  ],\n']);
end
try
    SequenceName = read_this_dicom_line('Sequence Name',TextAsCells);
    fprintf(fileID,['  "SequenceName": "' SequenceName '",\n']);
end
try
    ImageType = read_this_dicom_slashed_line('Image Type',TextAsCells);
    fprintf(fileID,['  "ImageType": [\n']);
    for i = 1:length(ImageType)-1
        fprintf(fileID,['    "' deblank(ImageType{i}) '",\n']);
    end
    fprintf(fileID,['    "' deblank(ImageType{end}) '"\n']);
    fprintf(fileID,['  ],\n']);
end
try
    SeriesNumber = read_this_dicom_line('Series Number',TextAsCells);
    fprintf(fileID,['  "SeriesNumber": "' SeriesNumber '",\n']);
end
try
    AcquisitionTime = read_this_dicom_line('AcquisitionTime',TextAsCells);
    fprintf(fileID,['  "Acquisition Time": "' AcquisitionTime '",\n']);
end
try
    AcquisitionNumber = read_this_dicom_line('Acquisition Number',TextAsCells);
    fprintf(fileID,['  "AcquisitionNumber": ' AcquisitionNumber ',\n']);
end
try
    SliceThickness = read_this_dicom_line('Slice Thickness',TextAsCells);
    fprintf(fileID,['  "SliceThickness": ' SliceThickness ',\n']);
end
try
    SpacingBetweenSlices = read_this_dicom_line('Spacing Between Slices',TextAsCells);
    fprintf(fileID,['  "SpacingBetweenSlices": ' SpacingBetweenSlices ',\n']);
end
try
    SAR = read_this_dicom_line('SAR',TextAsCells);
    fprintf(fileID,['  "SAR": ' SAR ',\n']);
end
try
    EchoTime = read_this_dicom_line('Echo Time',TextAsCells);
    fprintf(fileID,['  "EchoTime": ' EchoTime ',\n']);
end
try
    RepetitionTime = read_this_dicom_line('Repetition Time',TextAsCells);
    fprintf(fileID,['  "RepetitionTime": ' RepetitionTime ',\n']);
end
try
    FlipAngle = read_this_dicom_line('Flip Angle',TextAsCells);
    fprintf(fileID,['  "FlipAngle": ' FlipAngle ',\n']);
end
try
    PartialFourier = read_this_dicom_line('MeasuredFourierLines',TextAsCells); %I'm not 100% sure that this is the same
    fprintf(fileID,['  "PartialFourier": ' PartialFourier ',\n']);
end
% try
%     BaseResolution = read_this_dicom_line('Acquisition Matrix',TextAsCells); %I'm not 100% sure that this is the same
%     fprintf(fileID,['  "BaseResolution": ' BaseResolution ',\n']);
% end
try
    TransmitCoilName = read_this_dicom_line('Transmit Coil Name',TextAsCells);
    fprintf(fileID,['  "TransmitCoilName": "' TransmitCoilName '",\n']);
end
try
    CoilString = read_this_dicom_line('ImaCoilString',TextAsCells);
    fprintf(fileID,['  "CoilString": "' CoilString '",\n']);
end
try
    PulseSequenceDetails = read_this_dicom_line('PulseSequenceDetails',TextAsCells);
    fprintf(fileID,['  "PulseSequenceDetails": "' PulseSequenceDetails '",\n']);
end
try
    PercentPhaseFOV = read_this_dicom_line('Percent Phase Field of View',TextAsCells);
    fprintf(fileID,['  "PercentPhaseFOV": ' PercentPhaseFOV ',\n']);
end
try
    PhaseEncodingSteps = read_this_dicom_line('Number of Phase Encoding Steps',TextAsCells);
    fprintf(fileID,['  "PhaseEncodingSteps": ' PhaseEncodingSteps ',\n']);
end
try
    AcquisitionMatrixPE = read_this_dicom_line('AcquisitionMatrixText',TextAsCells);
    fprintf(fileID,['  "AcquisitionMatrixPE": ' AcquisitionMatrixPE ',\n']);
end
try
    PixelBandwidth = read_this_dicom_line('Pixel Bandwidth',TextAsCells);
    fprintf(fileID,['  "PixelBandwidth": ' PixelBandwidth ',\n']);
end
try
    DwellTime = read_this_dicom_line('RealDwellTime',TextAsCells);
    fprintf(fileID,['  "DwellTime": ' DwellTime ',\n']);
end
try
    PhaseEncodingDirection = read_this_dicom_line('PhaseEncodingDirectionPositive',TextAsCells);
    fprintf(fileID,['  "PhaseEncodingDirection": "' PhaseEncodingDirection '",\n']);
end
try
    all_stimes = dlmread(rawfile_stimes,' ');
    fprintf(fileID,['  "SliceTiming": [']);
    for i = 1:length(all_stimes)-1
        fprintf(fileID,['    "' num2str(all_stimes(i)) '",\n']);
    end
    fprintf(fileID,['    "' num2str(all_stimes(end)) '",\n']);
    fprintf(fileID,['  ],\n']);
end
try
    ImageOrientationPatientDICOM = read_this_dicom_slashed_line('Image Orientation (Patient)',TextAsCells);
    fprintf(fileID,['  "ImageOrientationPatientDICOM": [\n']);
    for i = 1:length(ImageOrientationPatientDICOM)-1
        fprintf(fileID,['    "' deblank(ImageOrientationPatientDICOM{i}) '",\n']);
    end
    fprintf(fileID,['    "' deblank(ImageOrientationPatientDICOM{end}) '"\n']);
    fprintf(fileID,['  ],\n']);
end
try
    InPlanePhaseEncodingDirectionDICOM = read_this_dicom_line('In-plane Phase Encoding Direction',TextAsCells);
    fprintf(fileID,['  "InPlanePhaseEncodingDirectionDICOM": "' InPlanePhaseEncodingDirectionDICOM '",\n']);
end
try
    fprintf(fileID,['  "ConversionSoftware": "Bespoke Matlab Script TEC",\n']);
end
try
    PRCPPSDescription = read_this_dicom_line('Requested Procedure Description',TextAsCells);
    fprintf(fileID,['  "PRCPPSDescription": "' PRCPPSDescription '",\n']);
end
try
    PatientID = read_this_dicom_line('Patient''s ID',TextAsCells);
    fprintf(fileID,['  "PatientID": "' PatientID '",\n']);
end
try
    AccessionNumber = read_this_dicom_line('Accession Number',TextAsCells);
    fprintf(fileID,['  "AccessionNumber": "' AccessionNumber '",\n']);
end
try
    AcquisitionDate = read_this_dicom_line('Study Date',TextAsCells);
    fprintf(fileID,['  "AcquisitionDate": ' AcquisitionDate ',\n']);
end
if strfind(outfile_dir,'func')
    fprintf(fileID,['  "BidsDataType": "func",\n']);
    fprintf(fileID,['  "BidsRedCapType": "taskFMRI",\n']);
    fprintf(fileID,['  "BidsModalityLabel": "bold",\n']);
elseif strfind(outfile_dir,'anat')
    fprintf(fileID,['  "BidsDataType": "anat",\n']);
    fprintf(fileID,['  "BidsRedCapType": "MP2RAGE",\n']);
    fprintf(fileID,['  "BidsModalityLabel": "MP2RAGE",\n']);
elseif strfind(outfile_dir,'fmap')
    fprintf(fileID,['  "BidsDataType": "fmap",\n']);
    fprintf(fileID,['  "BidsRedCapType": "FM",\n']);
    fprintf(fileID,['  "BidsModalityLabel": "fmap",\n']);
elseif strfind(outfile_dir,'dwi')
    fprintf(fileID,['  "BidsDataType": "dwi",\n']);
    fprintf(fileID,['  "BidsRedCapType": "DWI",\n']);
    fprintf(fileID,['  "BidsModalityLabel": "dwi",\n']);
end
try
    BidsTask = get_bids_detail('task',outfile_json);
    fprintf(fileID,['  "TaskName": "' BidsTask '",\n']);
    fprintf(fileID,['  "BidsTask": "' BidsTask '",\n']);
end
try
    BidsAcq = get_bids_detail('acq',outfile_json);
    fprintf(fileID,['  "BidsAcq": "' BidsAcq '",\n']);
end
fprintf(fileID,['  "BidsDerivedLabel": "",\n']);
fprintf(fileID,['}\n']);

    function dicom_output = read_this_dicom_line(field_value,TextAsCells)
        this_mask = ~cellfun(@isempty, strfind(TextAsCells, field_value));
        this_split_line = strsplit(TextAsCells{this_mask},' ');
        this_split_line = this_split_line(~cellfun('isempty',deblank(this_split_line)));
        dicom_output = this_split_line{end};
    end
    function dicom_multi_output = read_this_dicom_multi_line(field_value,TextAsCells)
        this_mask = ~cellfun(@isempty, strfind(TextAsCells, field_value));
        this_split_line = strsplit(TextAsCells{this_mask},' ');
        this_split_line = this_split_line(~cellfun('isempty',deblank(this_split_line)));
        field_value_split = strsplit(field_value,' ');
        this_header_number = find(~cellfun(@isempty, strfind(this_split_line, field_value_split{end})));
        dicom_multi_output = this_split_line(this_header_number+1:end);
    end
    function dicom_multi_slashed_output = read_this_dicom_slashed_line(field_value,TextAsCells)
        this_mask = ~cellfun(@isempty, strfind(TextAsCells, field_value));
        this_split_line = strsplit(TextAsCells{this_mask},{' ','\'},'CollapseDelimiters',true);
        this_split_line = this_split_line(~cellfun('isempty',deblank(this_split_line)));
        field_value_split = strsplit(field_value,' ');
        this_header_number = find(~cellfun(@isempty, strfind(this_split_line, field_value_split{end})));
        dicom_multi_slashed_output = this_split_line(this_header_number+1:end);
    end
    function bids_label = get_bids_detail(field_value,outfile_json)
        this_split_fname = strsplit(outfile_json,'_');
        this_mask = ~cellfun(@isempty, strfind(this_split_fname, field_value));
        bids_label = this_split_fname{this_mask};
    end
end
