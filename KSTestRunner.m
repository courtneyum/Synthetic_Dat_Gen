function KSTestRunner
methodNames = {'addX', 'MLE', 'probUpdate', 'unifOcc'};
cd 'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsReal\cardedOnly';
files = dir('*hist.fig');
files = {files.name};
index = regexp(files, '[pP]erDay');
index = cellfun(@isempty, index);
files = files(index);
weighted = zeros(size(files));
%weighted(1:2) = 1;


cd 'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen';
varNames = {'Plot Name', 'Method Name', 'Sample Size', 'Mean Divergence', 'Test Statistic From Mean (Z)', 'P-Value From Mean',...
    'Max Divergence', 'Reference Divergence', 'Test Statistic From Max (Z)', 'P-Value From Max'};
results = table([], [], [], [], [], [], [], [], [], [], 'VariableNames', varNames);

for i=1:length(files)
    for j=1:length(methodNames)
        [n, m, mean_divergence, max_divergence, p_mean, p_max, D_ref] = KSTest(strrep(files{i}, '.fig', ''), methodNames{j}, weighted(i));
        result = table({strrep(files{i}, '.fig', [])}, methodNames(j), n, mean_divergence, sqrt((m*n)/(m+n))*mean_divergence, p_mean, ...
            max_divergence, D_ref, sqrt((m*n)/(m+n))*max_divergence, p_max, 'VariableNames', varNames);
        results = [results; result];
    end
    close all;
end

writetable(results, 'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\KS Test Results\cumDistResults.csv');
save('C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\KS Test Results\cumDistResults.mat', 'results');
end