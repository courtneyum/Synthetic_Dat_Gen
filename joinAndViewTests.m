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

for i=2:length(files)
    load(files{i});
    mean_error.trad = mean_error.trad + coordination.mean_error_trad;
    mean_error.new = mean_error.new + coordination.mean_error_new;
    mean_error.prob = mean_error.prob + coordination.mean_error_prob;
    mean_error.est = mean_error.est + coordination.mean_error_est;
end

'';
end

function par = setup
    par.scratchDir = 'K:\My Drive\School\Thesis\Synthetic_Dat_Gen\Data\scratch\tests';
end