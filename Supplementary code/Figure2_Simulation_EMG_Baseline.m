% This script is to use Python function to simulate EMG baseline signals
clear classes
clc
addpath("MATLAB functions\")

%%
% Initialize Python interpreter
if count(py.sys.path,'') == 0
    insert(py.sys.path,int32(0),'');
end% Helper function to generate Laplace random numbers

% Import the module first
mixtureGenerator = py.importlib.import_module('MixtureModelSampleGenerator');
mixtureGenerator = py.importlib.reload(mixtureGenerator);

%% EMG simulation: Mixture Gaussian and Laplace distributions
% Signal parameter
fs = 5000;   % sampling frequency
duration = 40e-3;    % signal duration
samples_per_params = floor(fs * duration);
taxis = linspace(0, duration, samples_per_params);
num_signals = 10000;

% load matched filter, S05A
MUAP_list = importdata('Data/EMG_MUAP_filter_20250213183201.mat');
MUAP = MUAP_list(5).MUAP - mean(MUAP_list(5).MUAP);

% Mixture model parameters
gweight = 0.6254;
weights = [gweight, 1-gweight];
gaussian_params = [0.0271, 1.5514]; 
laplace_params = [-0.0680, 2.0248];

% results array
signals = zeros(num_signals, samples_per_params);
for icnt = 1:num_signals
    % generate baseline signal
    pyResult = mixtureGenerator.sample_mixture(int32(samples_per_params), ...
                                               py.list(weights), ...
                                               py.list({py.tuple(gaussian_params)}), ...
                                               py.list({py.tuple(laplace_params)}), ...
                                               pyargs('shuffle', true));
    signals(icnt, :) = double(pyResult);
end


% Matched filter Vpp
[~, ~, Vpp_mf] = get_decomp(signals, MUAP); 


%% Cross validation hyper-parameters
Vpp = Vpp_mf;
N = length(Vpp);
Kfold = 100;
cvIdx = crossvalind('kfold', Vpp, Kfold);

%
Vde = zeros([Kfold, 1]);
cv_table = table(Vde, Vde, Vde, Vde, 'VariableNames', {'GEV', 'Lognormal', 'Normal', 'Gamma'});
bic_table = table(Vde, Vde, Vde, Vde, 'VariableNames', {'GEV', 'Lognormal', 'Normal', 'Gamma'});
modelParameter = struct('GEV', [], 'Lognormal', [], 'Normal', [], 'Gamma', []);


% Distribution fit: CV
for icnt = 1:Kfold
    % test and training dataset
    testIdx = (cvIdx == icnt);
    trainIdx = ~testIdx;
    Dtest = Vpp(testIdx);
    Dtrain = Vpp(trainIdx);

    % GEV fit
    pd_gev = fitdist(Dtrain, 'Generalized Extreme Value');
    nloglike_gev = negloglik(pd_gev);
    bic_table.GEV(icnt) = calculateBIC(N, 3, nloglike_gev);
    cv_table.GEV(icnt) = sum(log(gevpdf(Dtest, ...
        pd_gev.ParameterValues(1), pd_gev.ParameterValues(2), pd_gev.ParameterValues(3))));
    modelParameter(icnt).GEV = pd_gev.ParameterValues;

    % lognormal fit
    pd_lgn = fitdist(Dtrain, 'Lognormal');
    nloglike_lgn = negloglik(pd_lgn);
    bic_table.Lognormal(icnt) = calculateBIC(N, 2, nloglike_lgn);
    cv_table.Lognormal(icnt) = sum(log(lognpdf(Dtest, pd_lgn.ParameterValues(1), pd_lgn.ParameterValues(2))));
    modelParameter(icnt).Lognormal = pd_lgn.ParameterValues;
    
    % normal fit
    pd_norm = fitdist(Dtrain, 'Normal');
    nloglike_norm = negloglik(pd_norm);
    bic_table.Normal(icnt) = calculateBIC(N, 2, nloglike_norm);
    cv_table.Normal(icnt) = sum(log(normpdf(Dtest, pd_norm.ParameterValues(1), pd_norm.ParameterValues(2))));
    modelParameter(icnt).Normal = pd_norm.ParameterValues;
    
    % Gamma distribution
    pd_gamma = fitdist(Dtrain, "Gamma");
    nloglike_gamma = negloglik(pd_gamma);
    bic_table.Gamma(icnt) = calculateBIC(N, 2, nloglike_gamma);
    cv_table.Gamma(icnt) = sum(log(gampdf(Dtest, pd_gamma.ParameterValues(1), pd_gamma.ParameterValues(2))));
    modelParameter(icnt).Gamma = pd_gamma.ParameterValues;
end


%% This is the full modified code section for your figure
close all
fig = figure('Color', [1 1 1]);
figWidth = 15;
figHeight = 22;
set(gcf,'unit','centimeters','position',[1, 2, figWidth, figHeight],...
    'PaperUnits','centimeters','PaperOrientation','landscape',...
    'PaperSize', [figWidth, figHeight]);

% main
t = tiledlayout(fig, 3, 1, "TileSpacing", "compact", "Padding", "compact");

% Subplot A: Simulated EMG signal
h(1) = nexttile(t, 1, [1, 1]);

% B: Vpp
h(2) = nexttile(t, 2, [1, 1]);

% C: BIC
h(3) = nexttile(t, 3, [1, 1]);

hold(h, "on")
set(h, 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on', 'TickDir', 'Both', ...
    'TickLabelInterpreter', 'Latex', 'FontSize', 13, 'FontName', 'Times New Roman')


%% Subplot A: EMG signal
plot(h(1), taxis*1000, signals(100, :), 'LineStyle', '-')
xlabel(h(1), 'Time (ms)', 'Interpreter', 'latex')
ylabel(h(1), 'EMG amplitude (μV)', 'Interpreter', 'tex')
set(h(1), 'YLim', [-15, 15])

%% Subplot B: Vpp distribution
histogram(h(2), Vpp_mf, 'Normalization', 'pdf', ...
          'FaceAlpha', 0.5, 'EdgeColor', 'none')
skewness(Vpp_mf)

% Model Selection
[~, Idx] = max(table2array(cv_table));
%
X = linspace(0, 2 * max(Vpp_mf), 1000);

% GEV
bp = modelParameter(Idx(1)).GEV;
p(1) = plot(h(2), X, gevpdf(X, bp(1), bp(2), bp(3)), 'LineWidth', 2, 'LineStyle', '-');
% Gamma
bp = modelParameter(Idx(4)).Gamma;
p(2) = plot(h(2), X, gampdf(X, bp(1), bp(2)), 'LineWidth', 2, 'LineStyle', ':');
% Lognormal
bp = modelParameter(Idx(2)).Lognormal;
p(3) = plot(h(2), X, lognpdf(X, bp(1), bp(2)), 'LineWidth', 2, 'LineStyle', '--');
% Normal
bp = modelParameter(Idx(3)).Normal;
p(4) = plot(h(2), X, normpdf(X, bp(1), bp(2)), 'LineWidth', 2, 'LineStyle', '-.');

% legend
legend(h(2), p, {'GEV distribution', 'Gamma distribution', 'Log-normal distribution', 'Normal distribution'}, ...
       'Box', 'off', 'Interpreter', 'tex', 'FontSize', 14)
xlabel(h(2), 'Peak-to-peak voltage V_{pp} (μV)', 'Interpreter', 'tex')
ylabel(h(2), {'Probability density', '(1/μV)'}, 'Interpreter', 'tex')
set(h(2), 'XLim', [0, 8])

% Store the colors from distribution lines for use in the BIC plot
distributionColors = cell(1,4);
for i = 1:4
    distributionColors{i} = get(p(i), 'Color');
end

%% Subplot C: BIC
uniXloc = [1, 3, 5, 7]; 
offset = 0.7 * linspace(-1, 1, 100);
uniXlabel = {'GEV', 'Gamma', 'Log-normal', 'Normal'};
xloc = repmat(uniXloc, Kfold, 1);
ybic = [bic_table.GEV, bic_table.Gamma, bic_table.Lognormal, bic_table.Normal];

% Order of data in subplot C (for clarity):
% Column 1: GEV
% Column 2: Gamma
% Column 3: Lognormal
% Column 4: Normal

% Clear previous plots and hold on
cla(h(3))
hold(h(3), 'on')

% Define color mapping - match colors from subplot B to subplot C
% Map distribution indices in subplot C to the p array indices
% p(1) = GEV, p(2) = Gamma, p(3) = Lognormal, p(4) = Normal
colorMapping = [1, 2, 3, 4];

% Loop through each distribution
for i = 1:4
    % Extract data for current distribution
    currXloc = xloc(:,i);
    currYbic = ybic(:,i);
    currColor = distributionColors{colorMapping(i)};
    
    % Create swarmchart for this distribution
    swarmchart(h(3), currXloc, currYbic, 20, 'MarkerFaceColor', currColor, 'Marker', 'o', ...
               'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.5, ...
               'XJitter', 'density', 'XJitterWidth', 1.2);
           
    % Create violinplot for this distribution
    violinplot(h(3), currXloc, currYbic, "DensityWidth", 1.2, "FaceColor", currColor, ...
               'EdgeColor', currColor, 'FaceAlpha', 0.1);
    
    % Add median line
    medianP(i) = plot(h(3), offset + uniXloc(i), median(currYbic) * ones(size(offset)), ...
               'LineStyle', '-', 'LineWidth', 2, 'Color', 'black');
end

% Use medianP for the legend to avoid overwriting p array
legend(h(3), medianP(1), {'Median'}, 'Interpreter', 'tex', 'box', 'off', 'FontSize', 14, 'Location', 'northwest')
ylabel(h(3), 'BIC', 'Interpreter', 'tex')
set(h(3), 'XTick', uniXloc, 'XTickLabel', uniXlabel, ...
    'XLim', [-1, 9])

%% Adding figure labels
addTileLabels(h, {'A', 'B', 'C'}, 'FontSize', 20, 'XOffset', -0.15);
exportgraphics(gcf, fullfile('Figures', 'Simulated EMG distribution.pdf'), "ContentType", "vector")


%%
% [p, h, stat] = ranksum(bic_table.GEV, bic_table.Gamma, 'tail', 'both', 'alpha', 0.05)
% % 
% [p, tvl, stats] = kruskalwallis([bic_table.GEV, bic_table.Lognormal, bic_table.Normal, bic_table.Gamma]);
% [c, m, h, gnames] = multcompare(stats, 'CriticalValueType', 'bonferroni');

%boxchart([bic_table.GEV, bic_table.Lognormal, bic_table.Normal, bic_table.Gamma])
