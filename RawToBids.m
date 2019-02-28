%% BIDS Creator for the experiment MRC_NIRG_WP1b, fMRI + Joystick data
%%Davide Aloi - PhD student University of Birmingham

%% INPUT
%RAW data should be organised as following:
%Experiment folder
    %Subject folder (C01,02,03 etc).
        %Condition folder (C01_SessionConditionName)
            %DICOM folder (if present)
                %DICOM files' names are not important BUT they should have at
                % the header SeriesDescription containing a string that
                % identify the series (e.g. fMRI_joystick_pre or T1_VOL)
            %or
            %NIFTI files containing the SeriesConditionName in their name
            %(e.g. sub-02_task-fMRIjoystickPre_bold.nii)
            %nb BIDS does't allow underscores in the task name (e.g.
            %fMRI_joystick_pre must be fMRIjoystickPre). This is the reason
            %why we will define 2 different variables: series_descriptions
            %(which must be equal to the one contained in DICOM headers or
            % in the name of the files .nii in your raw dataset)
            %and series_bids_labels, which should not have underscores.
     %...

%% OUTPUT
%RAW DICOM files are converted to nifty and a JSON sidecar files are created.
%The name of the file is created by reading the header "SeriesDescription"
%of the DICOM file and using the relative label defined in the
%variable series_bids_labels.
% E.g. sub-01_ses-SesName_task-TaskName.nii and
%sub-01_ses-SesName_task-TaskName.json.

%Alternatively, if files were already converted (in this case there should
%not be DICOM folders within the subject folders otherwise the script will
%convert the DICOM files within these folders instead of using the nifti
%files), the script will look for nifti files containing the condition name
%within their names.
%e.g. if the condition is fMRI_tdcs_pre, the nifti file should be:
%XXXXX_fMRI_tdcs_pre_XXXXXX.nifti

%nb: When a dicom folder is not present the script presumes that DICOM files
%have already been converted to nifti and it will look for .nii files. In
%this case the script will have to write a Json sidecar file. You should
%therefore insert the information that you want to have in your json
%sidecar file in the script block named "Create Sidecar JSon Document" below.

%The dataset is then organised according to the bids standard as following:
%Experiment folder (README,CHANGES,participants.tsv,dataset_description.json).
    %Subj-number
        %Ses (ses-sesName)
            %Subj-number.tsv (not in the script)
                %anat
                %func
                    %sub-n_ses-SesName_task-TaskName.json
                    %sub-n_ses-SesName_task-TaskName.nii
    %...

%% Initialisation
clearvars
clc

% Initalise SPM
spm('Defaults','fMRI');
spm_jobman('initcfg');

%% Define Key paths
% Define relevant paths
main_folder = 'C:\....\..\...\'; % Directory containing the directory with raw data
orig_dir = 'C:\....\..\...\MRI Raw data\'; % Directory with old structure
new_dir = 'C:\....\..\...\BIDS_dataset\'; % Directory where to put new file

%% Define other project variables
project_name = 'Project_Name_Here';
project_authors = {'Collaborator 1' 'Collaborator 2' 'Collaborator 3'};
references = {'https://www.daviniafernandezespejo.com/'};

labels = {'C01','C02','C03','C04','C05','C06','C07','C08','C09','C10','C11','C12','C13','C15','C16','C17','C18','C19','C20','C21','C22','C23'}; %subject folders in the raw data folder should have these names
new_labels = {'01','02','03','04','05','06','07','08','09','10','11','12','13','15','16','17','18','19','20','21','22','23'}; %Labels for BIDS structure
n_subj = numel(labels);
sub_folders = {'anat','func'}; % These are the subfolders you need in your BIDS dataset
conditions = {'bananas','pears','apples'}; %These are the conditions.
%Each subject should contain folders ending with these labels. E.g.
%C01_sN_conditionName

%This information is needed when you already have the NII files and you
%need to write a json sidecar file. The problem here is that the script
%does not distinguish anatomical/funcional nii files and it just create the
%same json files (which does not happen when you convert from DICON to NII
%as this information is taken from the DICOM header. Probably there is a
%better way to do it (like reading the appropriate nii header and use the
%information when creating the sidecar json).
repetition_time = 2.7; % Your repetition time
n_volumes   = 122; % Number of volumes (needed when writing the json file)

%If you have only 1 condition you can give it a random name as (e.g.
%'cond') and define it in the conditions variable above. Then keep the
%files for each subject in a folder name cond (as the script will open that
%folder to look for a DICOM folder or nii files). Each subject in the raw
%data should therefore have the following folder structure e.g C01 -> cond
%-> DICOM -> DICOM files (or if you have already converted dicom to nii C01 -> cond -> nii files).
%Then define the conditions_labels variable as = {''}. In this way no label will be added
%to your nifty files (as it's not needed)

conditions_labels = {'ses-bananas','ses-pears','ses-apples'};

%These are the series that will be converted to nifti or, when nifti
%relative to this series are available, they will be moved to their
%respective bids folder.
%Other files will be ignored.

series_descriptions = {'fMRI_task_pre','fMRI_task_post','T1_VOL_V1'};
%As I am interested only in the fMRI_task_pre, fMRI_task_post,
%Survey_SHC_32, T1_VOL_V1 and T2_VOL_V1 conditions, I do not convert resting state
%data to NIFTI, but the script can be easily adapted for such purpose.

%Tge variable series_bids_labels is needed as bids requires files to be named according to
%standardised rules. In this case, I want the fMRI files to have the
%condition in their name, but I want anatomical files to just end with T1w
%or T2w (defined in bids_endings) and this is why I will not assign any label to these files.

series_bids_labels = {'fMRTaskPre','fMRITaskPost',''};
%the following variable is needed when copying the files to the bids
%dataset. In this way I know that the first serie (fMRI_joystick_pre)
%refers to functional MRI and I will name the file properly.
bids_endings = {'_bold','_bold','_T1w'};

%The bids_beginnings variable is needed because in a valid bids dataset,
%files related to tasks should have the string "task" after the subject
%number. Anatomical files do not need to have such string so I keep their
%values empty.
bids_beginnings = {'_task-','_task-',''};

%Here we define if a series is anat or func. In this case I define that
%fMRI_task_pre and fMRI_task_post should be moved to the func
%subfolder whereas T1_VOL_V1 have to go to anat folders
series_type = {'func','func','anat'};


%% Create Dataset Description (Taken from Sara Calzolari's script)
cd(main_folder)
[status, msg, msgID] = mkdir(new_dir); % directory where to put json file and table with participants
cd(new_dir) % move to the new directory
% I also create a code folder
[status, msg, msgID] = mkdir('code'); % directory where of the code file
mri_json_name = 'dataset_description.json';
mri_json.Name               = project_name; % <- PROJECT NAME HERE
mri_json.BIDSVersion        = '1.1.1';
mri_json.License            = 'PDDL';
mri_json.Authors            = project_authors;   % <- YOUR NAME HERE
mri_json.HowToAcknowledge   = '';       % <- A REFERENCE/DOI HERE
mri_json.Funding            = '';       % <- FUNDING HERE
mri_json.ReferencesAndLinks = references;  % <- FURTHER LINKS (e.g. lab website)
json_options.indent         = '    ';
jsonSaveDir = fileparts(mri_json_name);
jsonwrite(mri_json_name,mri_json,json_options) %This function requires JSONio: a MATLAB JSON library (v1.2) --> https://github.com/gllmflndn/JSONio

%% Create Participants Table (Taken from Sara Calzolari's script)
% Add your data here
%script
participants_tsv_name = 'participants.tsv';
participant_id         = {'sub-03';'sub-04';'sub-05';'sub-07';'sub-09';'sub-10';'sub-11';'sub-12';'sub-13';'sub-14';'sub-15';'sub-16';'sub-17';'sub-18';'sub-19';'sub-20';'sub-21';'sub-22';'sub-23';'sub-24';'sub-25';'sub-26'};
age                    = [];
sex                    = {};
edinburgh_handedness   = [];
t = table(participant_id,age,sex,edinburgh_handedness);

writetable(t,participants_tsv_name,'FileType','text','Delimiter','\t');

%% Subject folders according to BIDS standard. For each subject sub_folders are created.

%Iteration for each subject
for idx = 1:numel(labels)
   cd(new_dir)
   disp(strcat('sub-',new_labels(idx)));
   [status, msg, msgID] = mkdir(char(strcat('sub-',new_labels(idx)))); % Create subject directory
   %creation of anat and func folders, as defined in the variable
   %sub_folders above
   for idx3 = 1:numel(conditions_labels)
       cd(char(strcat(new_dir,'sub-',new_labels(idx)))) %moving to the subject dir
       [status, msg, msgID] = mkdir(char(conditions_labels(idx3)));
       cd(char(strcat(new_dir,'sub-',new_labels(idx),'\',conditions_labels(idx3))));
       for idx2 = 1:numel(sub_folders)
           [status, msg, msgID] = mkdir(char(strcat(new_dir,'sub-',new_labels(idx),'\',conditions_labels(idx3),'\',sub_folders(idx2))));
           disp(char(sub_folders(idx2)))

       end
   end
end

%% Here I analyse the raw dataset and I iterate each subject
for idx = 1:numel(labels) %for each subject
    cd(char(strcat(orig_dir,labels(idx)))) %moving to subject folder
    listing = dir(cd); %I define the folders in each subject folder

    for k = 1:numel(listing) %I check condition folders for each subject. They should end in "_namecondition" (
        %disp(listing(k).name);
        %I open each subject folder and check if a DICOM folder is present.
        %The DICOM folder should contain nifti data that will converted to
        %NIFTI and moved to the BIDS dataset
        for j = 1:numel(conditions)
            cd(char(strcat(orig_dir,labels(idx))))
            try
                if char(listing(k).name(end-length(char(conditions(1)))+1:end)) == char(conditions(j))
                    disp(listing(k).name);
                    cd(char(listing(k).name)) %Moving to the condition folder
                    if exist('DICOM','dir')
                        %If the dicom folder is present, I look for the dicom
                        %files that I need (that is, only those within the
                        %series_descriptions variable defined above). If two
                        %dicom files within the same folder have the same
                        %series description, a timestamp will be added to the
                        %name of the nifti file. Each BIDS folder should therefore
                        % be revised.
                        cd('DICOM')
                        DICOM_FILES = dir(cd);
                        for i = 1:numel(DICOM_FILES) %I check each DICOM file in the folder
                            try
                                hdr = spm_dicom_headers(strcat(orig_dir,labels(idx),'\',char(listing(k).name),'\DICOM\',DICOM_FILES(i).name));
                                series_dscr = hdr{1,1}.SeriesDescription;
                                series_dscr = series_dscr(~isspace(series_dscr)); % cleaning the series lable in case there are spaces

                                if ismember(series_dscr,series_descriptions)
                                    %If the DICOM file refers to one of the
                                    %series I am interested in, I will
                                    %convert it to nifty. I will then move
                                    %it to the corresponding BIDS folder.
                                    %First I need to identify if the series
                                    %is an anatomical one or a functional
                                    %one (as defined above).
                                  index = find(strcmp(series_descriptions, series_dscr));
                                  disp(strcat('Found DICOM file with series description: ',char(series_dscr)));
                                  disp('----');
                                  disp(char(series_type(index)));
                                  % Now we select DICOM files that we want
                                  % to convert, and we move them to the
                                  % appropriate folder. To define whether a
                                  % file is anatomical or functional we
                                  % will check the variable series_type.

                                  % for conversion with creation of a separate JSON metadata file:
                                  meta = true;
                                  % We build the appropriate path
                                  outph = strcat(new_dir,'sub-',new_labels(idx),'\',conditions_labels(j),'\',char(series_type(index)));
                                  disp(outph)
                                  disp(strcat('Converting the file: ',' ',DICOM_FILES(i).name, ' to nifti'));
                                  disp(strcat('It will be saved here: ',' ',outph));
                                  %DICOM to NIFTI conversion
                                  files_converted = spm_dicom_convert(hdr,'all','flat','nii',cd,meta);
                                  filename = files_converted.files;
                                  disp(char(files_converted.files));
                                  disp('DONE');
                                  %%rename and move the file
                                  cd(char(outph));
                                  for xx = 1:numel(filename)
                                      file_without_extension = char(filename(xx));
                                      file_without_extension = file_without_extension(1:end-3);
                                      if ~exist(char(strcat('sub-',new_labels(idx),'_',char(conditions_labels(j)),bids_beginnings(index),series_bids_labels(index),bids_endings(index),'.nii')),'file')
                                        movefile(strcat(file_without_extension,'nii'),char(strcat('sub-',new_labels(idx),'_',char(conditions_labels(j)),bids_beginnings(index),series_bids_labels(index),bids_endings(index),'.nii')),'f');
                                        %%rename and move the json file
                                        movefile(strcat(file_without_extension,'json'),char(strcat('sub-',new_labels(idx),'_',char(conditions_labels(j)),bids_beginnings(index),series_bids_labels(index),bids_endings(index),'.json')),'f');
                                      else
                                       movefile(strcat(file_without_extension,'nii'),char(strcat('sub-',new_labels(idx),'_',char(conditions_labels(j)),bids_beginnings(index),series_bids_labels(index),'_',strrep(char(datestr(now,'HH:MM:SS.FFF')),':',''),bids_endings(index),'.nii')),'f');
                                       %%rename and move the json file
                                       movefile(strcat(file_without_extension,'json'),char(strcat('sub-',new_labels(idx),'_',char(conditions_labels(j)),bids_beginnings(index),series_bids_labels(index),'_',strrep(char(datestr(now,'HH:MM:SS.FFF')),':',''),bids_endings(index),'.json')),'f');
                                      end
                                  end
                                end
                                %disp(strcat(cd,'\',DICOM_FILES(i).name))
                            catch
                            disp('could not open the file:');
                            disp(char(DICOM_FILES(i).name));
                            end
                        end
                    else
                        %If DICOM folder does no exist use .nii files
                        %In this case I will iterate each file and check if
                        %the name contains one of the series description
                        %previously defined.
                        disp(strcat('DICOM folder not found for subject',labels(idx),', condition: ',conditions(j)));
                        disp('Nifti files will be used instead.');
                        nifti_files = dir(char(strcat(orig_dir,'',labels(idx),'\',char(listing(k).name))));
                        %I iterate the files, and copy only the ones that
                        %have one of the conditions I am interested in
                        %within the name
                        for ii = 1:numel(nifti_files)

                            for iii = 1:numel(series_descriptions)
                                if ~isempty(strfind(char(nifti_files(ii).name),char(series_descriptions(iii)))) && ~isempty(strfind(char(nifti_files(ii).name),char('nii')))
                                    disp(char(nifti_files(ii).name))
                                    %I move and rename the nifti file to
                                    %the bids dataset
                                    index = iii;
                                    file_to_move = strcat(char(strcat(orig_dir,'',labels(idx),'\',char(listing(k).name))),'\',char(nifti_files(ii).name));
                                    outph = strcat(new_dir,'sub-',new_labels(idx),'\',conditions_labels(j),'\',char(series_type(index)));
                                    cd(char(outph));
                                    %I move the file and create a json with
                                    %the info about the description
                                    if ~exist(char(strcat('sub-',new_labels(idx),'_',char(conditions_labels(j)),bids_beginnings(index),series_bids_labels(index),bids_endings(index),'.nii')),'file')
                                        movefile(file_to_move,char(strcat('sub-',new_labels(idx),'_',char(conditions_labels(j)),bids_beginnings(index),series_bids_labels(index),bids_endings(index),'.nii')),'f');
                                        disp(strcat('I moved the file'))
                                    else
                                        movefile(file_to_move,char(strcat('sub-',new_labels(idx),'_',char(conditions_labels(j)),bids_beginnings(index),series_bids_labels(index),'_',strrep(char(datestr(now,'HH:MM:SS.FFF')),':',''),bids_endings(index),'.nii')),'f');
                                        disp(strcat('I moved the file but since a file with that name was already present, I added a timestamp to the name to avoid replacement'))
                                    end

                                    %% Create Sidecar JSon Document. This part was taken from Sara Calzolari'script.
                                    
                                    % This Json sidercar file is created when the nifti file is moved. Change the information
                                    mri_json_name = char(strcat('sub-',new_labels(idx),'_',char(conditions_labels(j)),bids_beginnings(index),series_bids_labels(index),bids_endings(index),'.json'));
                                    % change these fields as you like
                                    mri_json.TaskName                           = char(series_descriptions(iii));
                                    mri_json.InstitutionName                    = 'University of XXXXXX';
                                    mri_json.InstitutionAddress                 = '';
                                    mri_json.Manufacturer                       = 'brand of your scanner';
                                    mri_json.ManufacturersModelName             = 'Model of your scanner';
                                    mri_json.Modality                           = 'MR';
                                    mri_json.MagneticFieldStrength              = '3T';
                                    mri_json.DeviceSerialNumber                 = '17117';
                                    mri_json.StationName                        = 'PHILIPS-PB7FMRS';
                                    mri_json.BodyPartExamined                   = 'BRAIN';
                                    mri_json.PatientPosition                    = 'HFS';
                                    mri_json.ProcedureStepDescription           = '2016-247';
                                    mri_json.SoftwareVersion                    = 'software version used';
                                    mri_json.MRAcquisitionType                  = '2D';
                                    mri_json.SeriesDescription                  = char(series_descriptions(iii));
                                    mri_json.ProtocolName                       = char(series_descriptions(iii));
                                    mri_json.ScanningSequence                   = 'GR';
                                    mri_json.SequenceVariant                    = 'SK';
                                    mri_json.ScanOptions                        = 'FS';
                                    mri_json.ImageType                          = ['ORIGINAL' 'PRIMARY' 'M' 'FFE' 'M' 'FFE'];
                                    mri_json.SeriesNumber                       = 701;
                                    mri_json.AcquisitionTime                    = 11:18:39.680000;
                                    mri_json.AcquisitionNumber                  = 7;
                                    mri_json.PhilipsRescaleSlope                = 0.773382;
                                    mri_json.PhilipsRescaleIntercept            = 0;
                                    mri_json.PhilipsScaleSlope                  = 0.000341801;
                                    mri_json.UsePhilipsFloatNotDisplayScaling   = 1;
                                    mri_json.SliceThickness                     = 3;
                                    mri_json.SpacingBetweenSlices               = 3;
                                    mri_json.RepetitionTime                     = repetition_time;
                                    mri_json.EchoTime                           = 0.0345;
                                    mri_json.FlipAngle                          = 79.09999985;
                                    mri_json.VolumeTiming                       = (0:n_volumes-1) * repetition_time;
                                    mri_json.NumberOfVolumesDiscardedByScanner  = 2;
                                    mri_json.NumberOfVolumesDiscardedByUser     = 0;
                                    mri_json.VoxelSize                          = [3 3 3];
                                    mri_json.Slices                             = 34;
                                    mri_json.PercentPhaseFOV                    = 100;
                                    mri_json.EchoTrainLength                    = 43;
                                    mri_json.PhaseEncodingSteps                 = 80;
                                    mri_json.AcquisitionMatrixPE                = 80;
                                    mri_json.ReconMatrixPE                      = 80;
                                    mri_json.PixelBandwidth                     = 2420.37;
                                    mri_json.ImageOrientationPatientDICOM       = [0.999557
                                        -1.25212e-10
                                        -0.0297452
                                        -0.00825085
                                        0.960759
                                        -0.277262  ];

                                    json_options.indent                         = '    '; % this makes the json look pretier when opened in a txt editor

                                    jsonwrite(mri_json_name,mri_json,json_options)
                                end

                            end
                        end

                    end
                end
            catch
                %do nothing
            end
        end
    end
end
