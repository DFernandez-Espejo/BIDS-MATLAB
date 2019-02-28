%%Json Fixer for BIDS datasets.
%Davide Aloi, PhD student.
%This script can be useful if you need to change a value within the json
%sidecar files of your BIDS dataset. E.g. I want to edit the VolumeTiming
%field of my Json files. I will therefore iterate each folder, open the
%Json file and change the value. The same reasoning can be applied to any
%other field you need to edit. 

%% Here's a few parameters you need to define
new_labels = {'01','02','03','04','05','06','07','08','09','10','11','12','13','15','16','17','18','19','20','21','22','23'}; %Labels for BIDS structure
sub_folders = {'func'}; % These are the subfolders that you want to look in, now I am interested in editing only json in the func folder
conditions = {'bananas','pears','apples'}; % Conditions
new_dir = 'C:\XXXXXXX\XXXXXX\XXXXXX\BIDS_dataset\'; % Directory of your bids dataset 
%The structure of your bids dataset should be as following:
%Experiment folder (README,CHANGES,participants.tsv,dataset_description.json).
    %Subj-number
        %Ses (ses-sesName)
            %Subj-number.tsv (not in the script)
                %anat
                %func
                    %sub-n_ses-SesName_task-TaskName.json
                    %sub-n_ses-SesName_task-TaskName.nii
    %...
  
%% Iteration
for i = 1:numel(new_labels)
    folder = strcat(new_dir,'sub-',new_labels(i));
    disp(folder);
    for ii = 1:numel(conditions)
        folder_c = strcat(folder,'\ses-',conditions(ii));
        for iii = 1:numel(sub_folders)
            folder_s = strcat(folder_c,'\',sub_folders(iii),'\');
            disp (folder_s);
            files = dir(char(folder_s));
            for x = 1:numel(files)
                if strfind(char(files(x).name),'.json') % If strfind doesn't work use "contains"
                    % I open the Json file and read its content. I then
                    % save it in the variable Val
                    disp(strcat('Json sidecar file found for subject:' ,new_labels(i)));
                    fname = (char(strcat(folder_s,files(x).name)));
                    disp(files(x).name);
                    fid = fopen(fname); 
                    raw = fread(fid,inf); 
                    str = char(raw'); 
                    fclose(fid);
                    val = jsonread(str); % this variable contains the all the json file
                    
                    %% HERE you can edit and save the json file as you need
                    %So now you have opened the json file and you can edit
                    % the field that you need to change. You just need to
                    % edit the field of the variable Val you are interested
                    % in. In my case I want to add a new field called
                    % Volume Timing
                    
                    % I want to calculate the Volumes (Acquisition duration/repetition time) 
                    RT = 2.7;
                    n_volumes = 122.9774;
                    volumes =  (0:n_volumes-1) * RT;
                    val.VolumeTiming = volumes;
                    
                    % Here I need to change the protocolName with the value
                    % assigned to seriesDescription (which is present only
                    % in some json files because I made a mistake so I need
                    % to check whether the field exists before I update the
                    % value).
                    
                    if ~isfield(val.acqpar,'SeriesDescription')
                        val.ProtocolName = val.SeriesDescription;
                    end
                    % Here I just need to update a few fields that were not
                    % correctly defined.
                    val.AcquisitionDuration = 332.03900146484381;
                    val.Slices = 46;
                    jsonwrite(fname,val) % I update the Json file with the new/adjusted information
                    
                end
            end
        end
        
    end
    
end