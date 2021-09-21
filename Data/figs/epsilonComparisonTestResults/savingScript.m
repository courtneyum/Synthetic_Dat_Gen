% Get filenames
saveFolder = 'log scale';
fileTemplate = [saveFolder, '\epsilonComparisonTestResultsAlpha*.fig'];
d=dir(fileTemplate);
folder={d.folder}; name={d.name};
filenames=cellfun(@fullfile, folder, name, 'UniformOutput', false);
alpha = zeros(length(filenames), 1);
k = 100;
%data = zeros(1e8, length(filenames), 'single');

for i=1:length(filenames)
    fig = openfig(filenames{i});
    children = get(fig, 'Children');
    children = get(children, 'Children');
    
    [path, name, ext] = fileparts(filenames{i});
    startIndex = regexp(name, '-?[01]\.?[1-9]?');
    alpha(i) = str2double(name(startIndex:end));
    
    path = regexprep(path, ['\\', saveFolder], '');
    %data(:, i) = children.YData;
    
    h = figure;
    plot(log10(1:length(children.YData)), movmean(children.YData, k), '.');
    title(['alpha = ', num2str(alpha(i)), ' k = ', num2str(k)]);
    xlabel('Log Iteration Number');
    ylabel('Log Mean Absolute Error');
    filename = fullfile(path, [saveFolder, ' smoothed'], [name, '.', 'fig']);
    savefig(filename);
    filename = fullfile(path, [saveFolder, ' smoothed'], [name, '.', 'png']);
    saveas(h, filename);
    
    
%     h = figure;
%     plot(children.YData, '.');
%     title(['alpha = ', alpha]);
%     ylabel('Mean Absolute Error');
%     xlabel('Iteration Number');
%     filename = fullfile(path, 'not log scale', [name, '.', 'fig']);
%     savefig(filename);
%     filename = fullfile(path, 'not log scale', [name, '.', 'png']);
%     saveas(h, filename);
%     
%     h = figure;
%     plot(log10(1:length(children.YData)), log10(children.YData), '.');
%     title(['alpha = ', alpha, ' Log Scale']);
%     ylabel('log(Mean Absolute Error)');
%     xlabel('log(Iteration Number)');
%     filename = fullfile(path, 'log scale', [name, '.', 'fig']);
%     savefig(filename);
%     filename = fullfile(path, 'log scale', [name, '.', 'png']);
%     saveas(h, filename);
     close all
end

% for i=1:length(filenames)
%     b = boxchart(data(:, i));
%     xticklabels(xtickLabels(i));
%     xlabel('alpha');
%     ylabel('Mean Absolute Error');
%     title(['Distributions of Mean Absolute Error For Alpha = ', xtickLabels{i}]);
%     b.JitterOutliers = 'on';
%     b.MarkerStyle = '.';
%     
%     filename = [pwd, 'boxplots', 'alpha=', strtrim(xtickLabels{i})];
%     savefig([filename, '.fig']);
%     saveas(b, [filename, '.png']);
% end

'';