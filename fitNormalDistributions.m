function fitNormalDistributions
    
    figDirs = {'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsSingleProcess\staticReplacement\addX', ...
        'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsSingleProcess\staticReplacement\MLE', ...
        'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsSingleProcess\staticReplacement\probUpdate', ...
        'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsSingleProcess\staticReplacement\unifOcc', ...
        'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsReal\cardedOnly'};
    files = {'CIhist', 'CIEventDataHist', 'durationHist', 'gamesPerMinHist'};
    weighted = [0,1,0,0];
    weighted = logical(weighted);
    weighted = logical([0]);
    files = {'CIHist'};
    
    varNames = {'Fig Dir', 'Fig Name', 'Fig Number', 'Mu', 'Sigma', 'Total Residual'};
    results = table([], [], [], [], [], [], 'VariableNames', varNames);
    
    for j=1:length(figDirs)
        figDir = figDirs{j};
        saveDir = fullfile(figDir, 'fittedDists');
        if ~exist(saveDir, 'dir')
            mkdir(saveDir);
        end
        for i=1:length(files)
            h = openfig(fullfile(figDir, [files{i}, '.fig']));
            ax = gca(h);
            histo = get(ax, 'Children');
            data = histo.Data;
            data(isnan(data)) = [];
            data(isinf(data)) = [];
            mu = mean(data);
            sigma = sum((data - mu).^2)/(length(data) - 1);
            sigma = sqrt(sigma);

            binEdges = histo.BinEdges;
            binMidpoints = (binEdges(1:end-1) + binEdges(2:end))/2;
            normalDist = -0.5*((binMidpoints - mu)/sigma).^2;
            normalDist = 1/(sigma*sqrt(2*pi))*exp(normalDist);
            normalDist = normalDist/sum(normalDist);

            scrsz = get(0,'ScreenSize');
            h = figure('Position',scrsz);
            hold on;
            plot(gca(h), binMidpoints, normalDist, 'b.');

            relativeFrequency = histo.Values/sum(histo.Values);
            plot(binMidpoints, relativeFrequency, 'r.');
            
            
            disp(['Mu=', num2str(mu), ' sigma=', num2str(sigma), ' residual=', num2str(sum(abs(relativeFrequency - normalDist)))]);
            
            [sigma, mu, error] = GaussNewton(binMidpoints(:), relativeFrequency(:), sigma, mu, weighted(i));
            
            normalDist = -0.5*((binMidpoints - mu)/sigma).^2;
            normalDist = 1/(sigma*sqrt(2*pi))*exp(normalDist);
            normalDist = normalDist/sum(normalDist);
            plot(gca(h), binMidpoints, normalDist, 'g.');
            title(ax.Title.String);
            xlabel(ax.XLabel.String);
            ylabel(gca(h), 'Relative Frequency');
            legend(gca(h), 'Fitted Distribution', 'Actual Distribution', 'Least Squares Regression');
            
            saveas(gcf, fullfile(saveDir, [files{i}, '.fig']));
            saveas(gcf, fullfile(saveDir, [files{i}, '.png']));
            
            result = table({figDir}, files(i), i, mu, sigma, sum(abs(relativeFrequency - normalDist)), 'VariableNames', varNames);
            results = [results; result];
        end
    end
    save('Data\normalDistFittingResults', 'results');
end

