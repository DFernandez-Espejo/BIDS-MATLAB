%% Double blinder for BIDS
% Davide Aloi - PhD student - University of Birmingham
% Based on Sara Carlzolari's script - PhD student - University of
% Birmingham

%% How To Use
% The structure of your dataset should follow the BIDS criteria (see
% http://bids.neuroimaging.io/)
% This script applies new labels to all the files and folders of a BIDS
% dataset. 
% You just need to define the path of the folder containing the subject
% folders and your sessions. In this example session1, session2 and
% session3 will be renamed kiwi, avocado and pineapple for all the 6
% subjects. 

% E.g.
% Main folder
%	Sub-01
%       ses-session1
%           func
%               sub-01_ses-session1_task-TASKNAME_bold.nii 
%               sub-01_ses-session1_task-TASKNAME_bold.json
% Will become
%	Sub-01
%       ses-kiwi
%           func
%               sub-01_ses-kiwi_task-TASKNAME_bold.nii 
%               sub-01_ses-kiwi_task-TASKNAME_bold.json


%% Main Variables
bids_folder = 'C:\XXX-XXX\XXX\XXX\bidsdataset\';
sessions = {'session1','session2','session3'}; % The original labels
sub_folders = {'anat','func'};
labels = {'03','04','05','06'}; % Subject labels
% IMPORTANT FOR  DOUBLE BLIND!!! %%
new_names =  {'kiwi','avocado','pineapple'}; % To be assigned by another researcher 

%% Iteration
% This script will iterate each subject folder in the main bids_folder and assign new
% the new labels to the sub-folders and all the files. 
for i = 1:numel(labels)
    folder = strcat(bids_folder,'sub-',labels(i));
    disp(strcat('Applying new labels to sbj:',labels(i)));
    for ii = 1:numel(sessions)
        folder_c = strcat(folder,'\ses-',sessions(ii));
        for iii = 1:numel(sub_folders)
            folder_s = strcat(folder_c,'\',sub_folders(iii),'\');
            files = dir(char(folder_s));
            % Iterating files
            if ~numel(files) == 0 
                for x = 1:numel(files)
                    if strfind(char(files(x).name),char(sessions(ii))) % If strfind doesn't work use "contains"
                       new_file_name = strrep(files(x).name,strcat('ses-',char(sessions(ii))),strcat('ses-',char(new_names(ii))));
                       movefile(char(strcat(folder_s,files(x).name)),char(strcat(folder_s,new_file_name)));
                    end
                end
            end
        end  
    % Applying new names to the sub folder
    new_folder = strcat(folder,'\ses-',new_names(ii));
    movefile(char(folder_c),char(new_folder));   
    end
end