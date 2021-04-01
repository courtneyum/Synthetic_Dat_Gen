function joinAndSaveEVD

    par0 = setup;
    load(par0.converterCoordinationFile);
    par0 = coordination.par;
    fileTemplate=fullfile(par0.scratchEVD, [par0.EVDRootFilename, '*']);
    %[par0.transMatRootFileName, '.*']);
    EVDFiles = getEVDFiles(fileTemplate);
    EVD = [];
    
    for i=1:length(EVDFiles)
        disp(['Loading file ', num2str(i), '\', num2str(length(EVDFiles))]);
        load(EVDFiles{i});
        % cutoff the last 2 days or else we will get a cycle with a period
        % the length of a file
        index = floor(data.numericTime) == floor(max(data.numericTime));
        data(index, :) = [];
        index = floor(data.numericTime) == floor(max(data.numericTime));
        data(index, :) = [];
        
        if ~isempty(EVD)
            timeOffset = max(EVD.numericTime) - min(EVD.numericTime) + 1/(24*60*60);
        else
            timeOffset = 0;
        end
        
        data.numericTime = data.numericTime + timeOffset;
        data.time = datetime(data.numericTime, 'ConvertFrom','datenum');
        EVD = [EVD; data];
    end
    filename = fullfile(par0.dataDir, par0.EVDGenFilename);
    disp(['Saving EVD to ', filename]);
    save(filename, 'EVD');
    writetable(EVD, [filename, '.csv']);
end

function files=getEVDFiles(fileTemplate)
    % Get filenames matching the sessionTemplate. files are assumed to be
    % numbers, and are returned in numerically sorted order.
    d=dir(fileTemplate);
    fileNumbers=regexp({d.name}, '(\d+)\.mat$', 'tokens');
    delIndex = cellfun(@isempty, fileNumbers);
    d(delIndex) = [];
    fileNumbers=[fileNumbers{:}]; fileNumbers=[fileNumbers{:}];
    fileNumbers=str2double(fileNumbers);
    [~,index]=sort(fileNumbers);
    d=d(index);
    folder={d.folder}; name={d.name};
    files=cellfun(@fullfile, folder, name, 'UniformOutput', false);
end

function par = setup
     % Get the name of the Google Drive root. This location can be set by
% running: setpref('nQube', 'GDriveRoot', 'E:\Shared drives'); or other
% location.

    try
        GDriveRoot=getpref('School', 'GDriveDataRoot');
    catch err
        disp('*** PLEASE SET A PREFERENCE FOR YOUR GDRIVE LOCATION ***');
        rethrow(err);
    end

    par.converterCoordinationFile = fullfile(GDriveRoot, 'Synthetic_Dat_Gen', 'Data', 'scratch', 'coordination.mat');
end