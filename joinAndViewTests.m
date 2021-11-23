function joinAndViewTests
par = setup;
fileTemplate=fullfile(par.scratchDir, ['coordination', '*']);

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

load(files{1});
mean_error.trad = coordination.mean_error_trad;
mean_error.new = coordination.mean_error_new;
mean_error.prob = coordination.mean_error_prob;
mean_error.est = coordination.mean_error_est;
max_error.trad = coordination.max_error_trad;
max_error.new = coordination.max_error_new;
max_error.prob = coordination.max_error_prob;
max_error.est = coordination.max_error_est;
% num_iters = coordination.num_iters;
% error = coordination.error;

for i=2:length(files)
    load(files{i});
    mean_error.trad = mean_error.trad + coordination.mean_error_trad;
    mean_error.new = mean_error.new + coordination.mean_error_new;
    mean_error.prob = mean_error.prob + coordination.mean_error_prob;
    mean_error.est = mean_error.est + coordination.mean_error_est;
    max_error.trad = max_error.trad + coordination.max_error_trad;
    max_error.new = max_error.new + coordination.max_error_new;
    max_error.prob = max_error.prob + coordination.max_error_prob;
    max_error.est = max_error.est + coordination.max_error_est;
%     num_iters = num_iters + coordination.num_iters;
%     error = error + coordination.error;
end

% for i=1:size(error, 1)
%     error(i,1) = NaN; % make it so zero at beginning won't display
%     scatter(1:coordination.par.NSteps, error(i, :), 8, 'filled');
%     title(['alpha = ', num2str(coordination.par.alpha(i))]);
%     ylabel('Mean Absolute Error');
%     xlabel('Iteration Number');
%     savefig(['K:\My Drive\School\Thesis\Synthetic_Dat_Gen\Data\figs\epsilonComparisonTestResultsAlpha', num2str(coordination.par.alpha(i)), '.fig']);
% end

'';
end

function par = setup
    par.scratchDir = 'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\scratch\tests';
end