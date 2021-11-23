% Normality Testing
figNames = {'CIEventDataHist', 'CISessionDataHist', 'durationHist', 'gamesPerMinHist'};
methodNames = {'AddX', 'MLE', 'ProbUpdate', 'UnifOcc', 'Real'};


varNames = {'MethodName', 'FigName', 'Mean', 'StandardDeviation', 'Skewness', 'SkewnessError', 'Kurtosis', 'KurtosisError', 'Z_s', 'Z_k', 'PValue'};
results = table([], [], [], [], [], [], [], [], [], [], [], 'VariableNames', varNames);

for j=1:length(methodNames)
    if strcmpi(methodNames{j}, 'real')
        figDir = 'C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsReal\cardedOnly';
    else
        figDir = fullfile('C:\Users\cbonn\Documents\Thesis\Synthetic_Dat_Gen\Data\figs\resultsSingleProcess\staticReplacement', methodNames{j});
    end

    saveDir = fullfile(figDir, 'fittedDists');
    for i=1:length(figNames)
        h = openfig(fullfile(figDir,[figNames{i}, '.fig']));
        ax = get(h, 'Children');
        histo = get(ax, 'Children');
        data = histo.Data;
        data(isnan(data)) = [];
        data(isinf(data)) = [];
        mu = mean(data);
        sigma = std(data);
        [S, SE_s] = skewness(data, mu, sigma);
        [K, SE_k] = kurtosis(data, mu, sigma);

        z_k = K/SE_k;
        z_s = S/SE_s;

        result = table(methodNames(j), figNames(i), mu, sigma, S, SE_s, K, SE_k, z_s, z_k, 0, 'VariableNames', varNames);
        results = [results; result];
    end
end


function [K, SE] = kurtosis(data, mu, sigma)
    n = length(data);
    K = ((data - mu)/sigma).^4;
    K = sum(K);
    K = K*n*(n+1)/((n-1)*(n-2)*(n-3));
    K = K - (3*(n-1)^2)/((n-2)*(n-3));
    
    SE = 24*n*(n-1)^2;
    SE = SE/((n-2)*(n-3)*(n+5)*(n+3));
    SE = sqrt(SE);
end

function [S, SE] = skewness(data, mu, sigma)
    n = length(data);
    S = (data-mu)/sigma;
    S = S.^3;
    S = sum(S)*n/((n-1)*(n-2));
    
    SE = 6*n*(n-1)/((n-2)*(n+1)*(n+3));
    SE = sqrt(SE);
end