function module_create_json(rawfilePath,outfilePath)
% A function for making JSON files from dicom headers to make everything
% into BIDS format

%read from here
rawfile_dcmhdr = strtok(rawfilePath,'.nii');
rawfile_dcmhdr = [rawfile_dcmhdr '.dcmhdr'];

%write to here
outfile_json = strtok(outfilePath,'.nii');
outfile_json = [outfile_json '.json'];

outfile_dir = fileparts(outfilePath);

%read in dicomfile as a reference
dcm_text = textread(rawfile_dcmhdr);
TextAsCells = regexp(dcm_text, '\n', 'split');

%open file for writing
fileID = fopen(outfile_json,'w');

%Preamble
fprintf(fileID,'{\n');

%Line by Line construction
Modality = read_this_dicom_line('Modality',TextAsCells);
fprintf(fileID,['{  "Modality": ' Modality ',\n']);
MagneticFieldStrength = read_this_dicom_line('Magnetic Field Strength',TextAsCells);
MagneticFieldStrength = num2str(round(str2num(MagneticFieldStrength)));
fprintf(fileID,['{  "MagneticFieldStrength": ' this_split_Model_number{1}(end) ',\n']);
ImagingFrequency = read_this_dicom_line('Imaging Frequency',TextAsCells);
fprintf(fileID,['{  "ImagingFrequency": ' ImagingFrequency ',\n']);
Manufacturer = read_this_dicom_line('Manufacturer',TextAsCells);
fprintf(fileID,['{  "Manufacturer": ' Manufacturer ',\n']);
ManufacturersModelName = read_this_dicom_line('Manufacturer''s Model Name',TextAsCells);
fprintf(fileID,['{  "ManufacturersModelName": ' ManufacturersModelName ',\n']);
InstitutionName = read_this_dicom_line('Institution Name',TextAsCells);
fprintf(fileID,['{  "InstitutionName": ' InstitutionName ',\n']);
fprintf(fileID,['{  "InstitutionalDepartmentName": ' InstitutionName ',\n']);
InstitutionAddress = read_this_dicom_line('Institution Address',TextAsCells);
fprintf(fileID,['{  "InstitutionAddress": ' InstitutionAddress ',\n']);
DeviceSerialNumber = read_this_dicom_line('Device Serial Number',TextAsCells);
fprintf(fileID,['{  "DeviceSerialNumber": ' DeviceSerialNumber ',\n']);
StationName = read_this_dicom_line('Station Name',TextAsCells);
fprintf(fileID,['{  "StationName": ' StationName ',\n']);
BodyPartExamined = read_this_dicom_line('BodyPartExamined',TextAsCells);
fprintf(fileID,['{  "Body Part Examined": ' BodyPartExamined ',\n']);
PatientPosition = read_this_dicom_line('Patient Position',TextAsCells);
fprintf(fileID,['{  "PatientPosition": ' PatientPosition ',\n']);
ProcedureStepDescription = read_this_dicom_line('Performed Procedure Step Descriptio',TextAsCells);
fprintf(fileID,['{  "ProcedureStepDescription": ' ProcedureStepDescription ',\n']);



  "ProcedureStepDescription": "P00363_MR1",
  "SoftwareVersions": "syngo_MR_B17",
  "MRAcquisitionType": "2D",
  "SeriesDescription": "WBIC_Resting_State",
  "ProtocolName": "WBIC_Resting_State",
  "ScanningSequence": "EP",
  "SequenceVariant": "SK",
  "ScanOptions": "FS",
  "SequenceName": "_epfid2d1_64",
  "ImageType": [
    "ORIGINAL",
    "PRIMARY",
    "M",
    "ND",
    "MOSAIC"
  ],
  "SeriesNumber": "10",
  "AcquisitionTime": "11:30:43.115000",
  "AcquisitionNumber": 1,
  "SliceThickness": 3,
  "SpacingBetweenSlices": 3.75,
  "SAR": 0.135111,
  "EchoTime": 0.03,
  "RepetitionTime": 2,
  "FlipAngle": 78,
  "PartialFourier": 1,
  "BaseResolution": 64,
  "ShimSetting": [
    -3305,
    -26897,
    -5383,
    707,
    357,
    -177,
    -103,
    -5
  ],
  "TxRefAmp": 315.207,
  "PhaseResolution": 1,
  "ReceiveCoilName": "HeadMatrix",
  "CoilString": "t:HEA;HEP",
  "PulseSequenceDetails": "%SiemensSeq%_ep2d_bold",
  "PercentPhaseFOV": 100,
  "PhaseEncodingSteps": 64,
  "AcquisitionMatrixPE": 64,
  "ReconMatrixPE": 64,
  "BandwidthPerPixelPhaseEncode": 33.245,
  "EffectiveEchoSpacing": 0.000469995,
  "DerivedVendorReportedEchoSpacing": 0.000469996,
  "TotalReadoutTime": 0.0296097,
  "PixelBandwidth": 2441,
  "DwellTime": 3.2e-06,
  "PhaseEncodingDirection": "j-",
  "SliceTiming": [
    1.945,
    1.8825,
    1.82,
    1.7575,
    1.695,
    1.63,
    1.5675,
    1.505,
    1.4425,
    1.38,
    1.3175,
    1.255,
    1.1925,
    1.13,
    1.0675,
    1.005,
    0.94,
    0.8775,
    0.815,
    0.7525,
    0.69,
    0.6275,
    0.565,
    0.5025,
    0.44,
    0.3775,
    0.315,
    0.25,
    0.1875,
    0.125,
    0.0625,
    0
  ],
  "ImageOrientationPatientDICOM": [
    0.999705,
    0.0115636,
    0.0213464,
    -1.11383e-08,
    0.879277,
    -0.476311
  ],
  "InPlanePhaseEncodingDirectionDICOM": "COL",
  "ConversionSoftware": "dcm2niix",
  "ConversionSoftwareVersion": "v1.0.20181125  GCC4.9.2",
  "PRCPPSDescription": "p00363",
  "PatientID": "22834",
  "AccessionNumber": "U-ID29883",
  "TaskName": "rest",
  "AcquisitionDate": "20131211",
  "BidsDataType": "func",
  "BidsTask": "task-rest",
  "BidsAcq": "acq-rest305",
  "BidsModalityLabel": "bold",
  "BidsDerivedLabel": "",
  "BidsRedCapType": "rsFMRI"
}



    function dicom_output = read_this_dicom_line(field_value,TextAsCells)
        this_mask = ~cellfun(@isempty, strfind(TextAsCells, field_value));
        this_split_line = strsplit(TextAsCells{this_mask},' ');
        dicom_output = this_split_line{end};
    end
end
