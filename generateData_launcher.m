function generateData_Launcher
    par = setup;
    if ispc
        [~,par.matlabStartupCmd]=fileparts(par.matlabStartupCmd);
    else
        par.matlabStartupCmd=par.matlabStartupCmd;
    end
    
    % Delete the scratchDir if it exists. Generate a new one.
%     if exist(par.scratchEVD, 'dir')
%         rmdir(par.scratchEVD, 's');
%     end
%     pause(5);
    if ~exist(par.scratchEVD)
        mkdir(par.scratchEVD);
    end
    if ~exist(fullfile(par.scratchEVD, 'checkpoints'))
        mkdir(fullfile(par.scratchEVD, 'checkpoints'));
    end
    
    disp('Generating Coordination Files');
    folder = par.scratchDir;
    baseName = regexprep(par.converterCoordinationFile, '(.*\\)+', '');
    baseName = regexprep(baseName, '.mat', '');
    filenames = dir(folder);
    filenames = struct2table(filenames);
    filenames = filenames.name;
    index = regexp(filenames, [baseName, '\d*.mat']);
    index = ~cellfun(@isempty, index);
    filenames = filenames(index);
    for i=1:length(filenames)
        delete(fullfile(folder, filenames{i}));
    end

    % Generate coordination file.
    coordination.par=par;
    save(fullfile(par.scratchEVD, par.converterCoordinationFile), 'coordination');

    thisDir=fileparts(which(mfilename));

    disp('Spinning up Processes');
    if par.NCores > 1
        for c=1:par.NCores
            %cmd=[par.matlabStartupCmd, ' ', par.matlabOptions, ' -r "cd(''', thisDir, '''); ', par.converterName, ';" &'];
            cmd=[par.matlabStartupCmd, ' ', par.matlabOptions, ' -r "cd(''', thisDir, '''); ', par.converterName, '(', num2str(c), 'par', ')', ';" &'];
            unix(cmd);
        end
    else
        %For testing
        generate(1, par);
        joinAndSaveEVD(par);
    end
end

function par = setup
    try
        %GDriveRoot=getpref('School', 'GDriveRoot');
        GDriveRoot = getpref('School', 'GDriveDataRoot');
    catch err
        disp('*** PLEASE SET A PREFERENCE FOR YOUR GDRIVE LOCATION ***');
        rethrow(err);
    end
    
    par.methodName = 'AddX';

    % Scratch directory.
    par.scratchDir=fullfile(GDriveRoot, 'Data', 'scratch');
    par.scratchEVD=fullfile(par.scratchDir, ['EVD_gen_', par.methodName]);
    par.EVDRootFilename=['EVD4Single',par.methodName];
    par.NCores=1;
    par.matlabStartupCmd=strrep(which('addpath'),...
        fullfile('toolbox', 'matlab', 'general', 'addpath.m'),...
        fullfile('bin', 'matlab'));
    % par.parallel.matlabOptions='-nodisplay -nodesktop -nosplash';
    par.matlabOptions='-nojvm -nodesktop -nosplash -singleCompThread -minimize';
    par.converterName = 'generate';
    par.converterCoordinationFile = 'coordination';
    par.dataDir = fullfile(GDriveRoot, 'Data');
    par.EVDFilename = 'EVD_datGen.mat';
    par.EVDGenFilename = ['EVDGen_Single', par.methodName, 'HighOcc'];
    par.paramsFilename = ['par', par.methodName, '.mat'];
    par.loadCheckpoint = true;
    params = load(fullfile(par.dataDir, par.paramsFilename));
    par.params = params.par;
    par.params.initEventCode = 901;
    par.params.startTime = datenum(2020, 6, 22, 0, 0, 0);
    par.params.num_iters = 1e5;
    par.params.J = 100;
    par.params.timeout = 2*3600; % 2 hr timeout in seconds
    par.params.EVD.filename = fullfile(par.dataDir, 'EVD_datGen.mat');
end