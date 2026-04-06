% Add SPM and other toolboxes to the MATLAB path
addpath('/blue/jjtanner/jjtanner/neurotools/spm8'); % Update with your actual SPM path
addpath('/blue/jjtanner/jjtanner/neurotools/batch_scripts_pcasl'); % Update with your actual ASL Toolbox path
addpath('/blue/jjtanner/jjtanner/neurotools/matlab_nifti'); % Update with your nifti and Analyze Matlab tools

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-pre_task-rest_run-01/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-pre_task-rest_run-02/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-pre_task-rest_run-03/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-pre_task-rest_run-04/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-pre_task-pain_run-01/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-pre_task-pain_run-02/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-pre_task-pain_run-03/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-pre_task-pain_run-04/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-post_task-rest_run-01/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-post_task-rest_run-02/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-post_task-rest_run-03/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-post_task-rest_run-04/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-post_task-pain_run-01/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-post_task-pain_run-02/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-post_task-pain_run-03/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');

% Read the list of files from the text file
fileList = '/blue/jjtanner/shared/proact/dcm2bids/derivatives/asl/ses-post_task-pain_run-04/file_list.txt'; % specify your text file name
fid = fopen(fileList, 'r');
files = textscan(fid, '%s');
fclose(fid);
files = files{1};

% Iterate over each file in the list
for fileIdx = 1:length(files)
    Filename = files{fileIdx};
    
    try
        % Load the 4D NIfTI file
        nii = load_untouch_nii(Filename);
        data = nii.img;
        
        % Check if the input is indeed a 4D file
        if ndims(data) ~= 4
            error(['Input NIfTI file ' Filename ' is not 4D']);
        end

        % Create output directory if it doesn't exist
        outputDir = fullfile(fileparts(Filename), '3D_volumes');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Iterate through each 3D volume in the 4D data
        numVolumes = size(data, 4);
        for i = 1:numVolumes
            % Extract the i-th 3D volume
            volume = data(:, :, :, i);

            % Create a new NIfTI structure for the 3D volume
            nii_3d = nii;
            nii_3d.img = volume;
            nii_3d.hdr.dime.dim(1) = 3; % Update the dimension in the header

            % Save the 3D volume
            outputFilename = fullfile(outputDir, sprintf('volume_%02d.nii', i));
            save_untouch_nii(nii_3d, outputFilename);
        end

        disp(['3D volumes for ' Filename ' have been saved successfully.']);

        % Perform ASL perfusion subtraction on the original 4D file
        asl_perf_subtract(Filename, 0, 0, ...
            1, [1 1 1 0 0 1 0 1 1], 1, 1, 0.85, 1, 1.5, ...
            1.5, (4250-1500-1500)/24, 13, [], [], '');

    catch ME
        % For errors, throw the exception
        disp(['Error with ' Filename ': ' ME.message]);
        rethrow(ME);
    end
end

disp('Processing completed for all files.');
