function JSDRunner
    methodNames = {'addX', 'MLE', 'probUpdate', 'unifOcc'};
    cd 'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsReal\cardedOnly';
    files = dir('*hist.fig');
    files = {files.name};
    index = regexp(files, '[pP]erDay');
    index = cellfun(@isempty, index);
    files = files(index);


    cd 'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen';
    varNames = {'Plot Name', 'Method Name', 'JSD'};
    results = table([], [], [], 'VariableNames', varNames);
    
    for i=1:length(files)
        for j=1:length(methodNames)
            JS = JSD(strrep(files{i}, '.fig', ''), methodNames{j});
            result = table({strrep(files{i}, '.fig', [])}, methodNames(j), JS, 'VariableNames', varNames);
            results = [results; result];
        end
        close all;
    end
    
    '';