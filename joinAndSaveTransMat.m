function joinAndSaveTransMat
    par0 = setup;
    load(par0.converterCoordinationFile);
    par0 = coordination.par;
    fileTemplate=fullfile(par0.scratchDir, 'transMat');
    %[par0.transMatRootFileName, '.*']);
    transMatFiles = getTransMatFiles(fileTemplate);
    load(transMatFiles{1});
    
    par0.playersCount = zeros(size(par0.uniquePlayers));
    par0.firstMachinesCount = zeros(size(par0.uniqueMachineNumbers));
    
    par = prepForIntegration(par, par0);
    
    trans_mat.cardIn = sparse(par.i.in, par.j.in, par.s.in);
    trans_mat.cardOut = sparse(par.i.out, par.j.out, par.s.out);
    par0.firstMachinesCount = par.firstMachinesCount;
    par0.playersCount = par.playersCount;
    delta = par.delta;
    
    for i=2:length(transMatFiles)
        load(transMatFiles{i});
        
        par = prepForIntegration(par, par0);
    
        trans_mat.cardIn = trans_mat.cardIn + sparse(par.i.in, par.j.in, par.s.in);
        trans_mat.cardOut = trans_mat.cardOut + sparse(par.i.out, par.j.out, par.s.out);
        par0.firstMachinesCount = par0.firstMachinesCount + par.firstMachinesCount;
        par0.playersCount = par0.playersCount + par.playersCount;
        
        deltaIndex = find(par.delta.key > 0);
        [m, n] = ind2sub(size(par.delta.key), deltaIndex);
        for j=1:length(deltaIndex)
            if delta.key(m(j), n(j)) == 0
                delta.length = delta.length + 1;
                delta.key(m(j), n(j)) = delta.length;
                index = delta.length;
                delta.CI(index) = {[]};
                delta.CO(index) = {[]};
                delta.GP(index) = {[]};
                delta.t(index) = {[]};
            end
            
            index = delta.key(m(j), n(j));
            
            delta.CI{index} = [delta.CI{index}; par.delta.CI{par.delta.key(m(j),n(j))}];
            delta.CO{index} = [delta.CO{index}; par.delta.CO{par.delta.key(m(j),n(j))}];
            delta.GP{index} = [delta.GP{index}; par.delta.GP{par.delta.key(m(j),n(j))}];
            delta.t{index} = [delta.t{index}; par.delta.t{par.delta.key(m(j),n(j))}];
        end
    end
    
    par0.trans_mat = trans_mat;
    par0.totalTransitions.cardIn = sum(par0.trans_mat.cardIn, 2);
    par0.totalTransitions.cardOut = sum(par0.trans_mat.cardOut, 2);
    par0.playersDist = par0.playersCount/sum(par0.playersCount);
    par0.firstMachinesDist = par0.firstMachinesCount/sum(par0.firstMachinesCount);
    par0.delta = delta;
    par = par0;
    
    save(fullfile(par.dataDir, par.transMatFilename), 'par');
end

function sessionsFiles=getTransMatFiles(fileTemplate)
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
    sessionsFiles=cellfun(@fullfile, folder, name, 'UniformOutput', false);
end

function par = prepForIntegration(par, par0)
    if max(par.i.in < par.N*par.E) || max(par.j.in < par.N*par.E)
        par.i.in = [par.i.in; par.N*par.E];
        par.j.in = [par.j.in; par.N*par.E];
        par.s.in = [par.s.in; 0];
    end
    if max(par.i.out < par.N*par.E) || max(par.j.out < par.N*par.E)
        par.i.out = [par.i.out; par.N*par.E];
        par.j.out = [par.j.out; par.N*par.E];
        par.s.out = [par.s.out; 0];
    end
    
    playersIndex = ismember(par0.uniquePlayers, par.uniquePlayers);
    playersCount = par.playersCount;
    par.playersCount = zeros(size(par0.uniquePlayers));
    par.playersCount(playersIndex) = par0.playersCount(playersIndex) + playersCount;
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