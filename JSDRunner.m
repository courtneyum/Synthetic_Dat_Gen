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
    
    writetable(results, 'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\JSD Test Results\JSDTestResults.csv');
    save('C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\JSD Test Results\JSDTestResults', 'results');
    
end

function makePlot
    load('C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\JSD Test Results\JSDHighOccTestResults');
    resultsHighOcc = results;
    load('C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\JSD Test Results\JSDTestResults');
    
    figure;
    hold on;
    jsd = results.JSD;
    plot(1:4:height(results), jsd(1:4:height(results)), 'r+');
    plot(2:4:height(results), jsd(2:4:height(results)), 'b+');
    plot(3:4:height(results), jsd(3:4:height(results)), 'g+');
    plot(4:4:height(results), jsd(4:4:height(results)), 'k+');
    
    jsd = resultsHighOcc.JSD;
    plot(1:4:height(results), jsd(1:4:height(results)), 'r*');
    plot(2:4:height(results), jsd(2:4:height(results)), 'b*');
    plot(3:4:height(results), jsd(3:4:height(results)), 'g*');
    plot(4:4:height(results), jsd(4:4:height(results)), 'k*');
    xlabel('Test Index');
    ylabel('JSD');
    title('Comparing Jensen-Shannon Divergences');
    legend({'AddX LowOcc', 'MLE LowOcc', 'ProbUpdate LowOcc', 'UnifOcc LowOcc', 'AddX HighOcc', 'MLE HighOcc', 'ProbUpdate HighOcc', 'UnifOcc HighOcc'});
    xticks(1:4:height(results));
    xticklabels(table2cell(results(1:4:height(results), 1)));
end