%%NII HEADER FIX REPETITION TIME - Davide Aloi PhD student - University of
%%Birmingham

%% Main variables
new_labels = {'01','02','03','04','05'}; %Labels for BIDS structure
sub_folders = {'func'}; % These are the subfolders you need in your BIDS dataset
conditions = {'bananas','pears','apples'};
new_dir = 'C:\Users\XXXXXX\XXXXX\your_bids_dataset_here\'; % Directory where to put new file
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
    
%% We iterate each subject 
for i = 1:numel(new_labels)
    folder = strcat(new_dir,'sub-',new_labels(i));
    disp(folder);
    for ii = 1:numel(conditions)
        folder_c = strcat(folder,'\ses-',conditions(ii));
        for iii = 1:numel(sub_folders)
            folder_s = strcat(folder_c,'\',sub_folders(iii),'\');
            disp (folder_s);
            nii_files = dir(char(folder_s));
            for x = 1:numel(nii_files)
                %For each subject we open all the NII files and we update
                %the header PixelDimensions(4) that refers to the
                %repetition time. In my case it was set to 0 instead of 2.7
                if strfind(char(nii_files(x).name),'.nii') %If strfind doesnt work use contains
                    disp('nii file found');
                    fname = (char(strcat(folder_s,nii_files(x).name)));
                    disp(fname);
                    %% Here you should define what NIFTI header you want to change. In my case is pixelDimensions(4).
                    % Fixing NII header --> Repetition time: here we fix the
                    % pix4dimension from 0 to 2.7 (repetition time)
                    info = niftiinfo(fname);
                    info.PixelDimensions(4) = 2.7;
                    V = niftiread(info);
                    niftiwrite(V,fname,info);
                end
            end
        end
        
    end
    
end