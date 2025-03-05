% This figure is to fit the mixture model to the experimental data.
% The experiment data is for the relaxed muscle.
% 
clear
clear classes
addpath("MATLAB functions\")
% Import the module first
mixtureFit = py.importlib.import_module('GaussianLaplaceMixture');
mixtureFit = py.importlib.reload(mixtureFit);


% Import EMG data, SA05
X = importdata('Data\EMG_SubjuctA05.mat'); % unit in uV

%% Background calibration, S05A
% Convert MATLAB array to Python numpy array
X_py = py.numpy.array(X);

% Create instance of the mixture model
model = mixtureFit.GaussianLaplaceMixture(int32(1), int32(1), int32(42));

% Fit the model
fitted_model = model.fit(X_py, pyargs('verbose', true, 'max_iter', int32(10000)));

% Get parameters using getter methods, python results
weights = double(fitted_model.get_weights().tolist());
gaussian_params = cell(fitted_model.get_gaussian_params()); gaussian_params = double(gaussian_params{1});
laplace_params = cell(fitted_model.get_laplace_params()); laplace_params = double(laplace_params{1});

% BIC score
loglikelihood = double(fitted_model.compute_log_likelihood(X_py));
BIC = 5 * log(length(X)) - 2*loglikelihood;

% theoretical pdf curve
XrangMax = max(abs(min(X)), max(X));
Xrand = linspace(-XrangMax, XrangMax, 10000);
x_py = py.numpy.array(Xrand);
pdf_mixture = double(fitted_model.pdf(x_py).tolist());

%% Background Vpp distribution
Vpp_baseline = importdata('Data\A05_Background_Noise_MEP.mat');
Vpp_baseline = Vpp_baseline' * 1000;  % convert to uV

% GEV fit
gev_parameter = mygevfit(Vpp_baseline);

% lognormal fit
pd_lgn = fitdist(Vpp_baseline, 'Lognormal');
lgn_parameter = pd_lgn.ParameterValues;

% normal fit
pd_norm = fitdist(Vpp_baseline, 'Normal');
norm_parameter = pd_norm.ParameterValues;

% Gamma distribution
pd_gamma = fitdist(Vpp_baseline, "Gamma");
gamma_parameter = pd_gamma.ParameterValues;

%% Figure config
close all
fig = figure('Color', [1 1 1]);
figWidth = 15;
figHeight = 22;
set(gcf,'unit','centimeters','position',[0, 0, figWidth, figHeight],...
    'PaperUnits','centimeters','PaperOrientation','landscape',...
    'PaperSize',[figWidth, figHeight]);

% color scheme
colorScheme = ["#8B0000";"#191970";"#D07F2C";"#1E7C4A";"#6F6DA1";"#6990A2"];

% main tiledlayout
t = tiledlayout(fig, 3, 1, "TileSpacing", "compact", "Padding", "compact");

% Subplot 1: Histogram of EMG
h(1) = nexttile(t, 1, [1, 1]);
% h(3) = axes(fig, "Position", [0.33, 0.54, 0.1, 0.35], 'BoxStyle', 'back', 'Box', 'on');

% Subplot 2: Histogram of Vpp
h(2) = nexttile(t, 2, [1, 1]);

% Subplot 3: BIC stacked bar plot
h(3) = nexttile(t, 3, [1, 1]);

hold(h, 'on')
set(h, 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on', 'TickDir', 'Both', ...
    'TickLabelInterpreter', 'tex', 'FontSize', 12, 'FontName', 'Times New Roman')



%% Subplot A: Histogram of EMG
histogram(h(1), X, 'Normalization', 'pdf', 'NumBins', 100, ...
          'FaceAlpha', 0.5, 'EdgeColor', 'none')
plot(h(1), Xrand, pdf_mixture, 'LineStyle', '-', 'LineWidth', 1.2)
set(h(1), 'XLim', [-10, 10], 'YLim', [0, 0.3])

% set xticks
% h(1).XTickLabelMode = 'manual';
% h(1).XTickLabel = arrayfun(@(x) sprintf('%.0f', x*1000), h(1).XTick, 'UniformOutput', false);


xlabel(h(1), 'EMG amplitude (μV)', 'Interpreter', 'tex')
ylabel(h(1), {'Probability density', '(1/μV)'}, 'Interpreter', 'tex')

% % create an inset
% histogram(h(3), X, 'Normalization', 'pdf', 'NumBins', 100, ...
%           'FaceAlpha', 0.5, 'EdgeColor', 'none')
% plot(h(3), Xrand, pdf_mixture, 'LineStyle', '-', 'LineWidth', 1.2)
% set(h(3), 'XLim', [-2e-4, 2e-4])



%% Subplot B: Distribution of Vpp
Xrand = linspace(-0.001, 1.05 * max(Vpp_baseline), 1000);
histogram(h(2), Vpp_baseline, 'Normalization', 'pdf', 'NumBins', 50, ...
          'FaceAlpha', 0.5, 'EdgeColor', 'none')
% GEV
bp = gev_parameter;
plot(h(2), Xrand, gevpdf(Xrand, bp(1), bp(2), bp(3)), ...
     'LineWidth', 1.5, 'LineStyle', '-');

% Gamma
bp = gamma_parameter;
plot(h(2), Xrand, gampdf(Xrand, bp(1), bp(2)), ...
     'LineWidth', 1.5, 'LineStyle', ':');

% Lognormal
bp = lgn_parameter;
plot(h(2), Xrand, lognpdf(Xrand, bp(1), bp(2)), ...
     'LineWidth', 1.5, 'LineStyle', '--');

% Normal
bp = norm_parameter;
plot(h(2), Xrand, normpdf(Xrand, bp(1), bp(2)), ...
     'LineWidth', 1.5, 'LineStyle', '-.');

legend(h(2), {'', 'GEV distribution', 'Gamma distribution', 'Log-normal distribution', 'Normal distribution'}, ...
       'Box', 'off', 'Interpreter', 'tex', 'FontSize', 14)
xlabel(h(2), 'Peak-to-peak voltage V_{pp} (μV)', 'Interpreter', 'tex')
ylabel(h(2), {'Probability density', '(1/μV)'}, 'Interpreter', 'tex')
set(h(2), 'YLim', [0, 0.35])

%% Subplot 3: stacked bar plot
models = {'GEV', 'Gamma', 'Log-normal', 'Normal'};
Best_unique =    [3,  3, 1, 0 ]';
Best_tied =      [12, 7, 6, 1 ]';
Worst_unique =  -[0,  0, 5, 14]';


xcat = categorical(models);
y = [Best_tied, Best_unique, Worst_unique];
cm = lines(3);
cm(2:3, :) = cm(1:2, :);
cm(1, :) = brighten(cm(1, :), 0.5);

h_b = bar(h(3), xcat, y, 'stacked', 'EdgeColor', 'none', 'FaceColor', 'Flat', 'FaceAlpha', 0.5);

for ii = 1 : 3
    h_b(ii).CData = cm(ii, :);
end

ylabel(h(3), {"Number of subjects", "with best and worst fits"}, 'Interpreter', 'tex')
set(h(3), 'YLim', [-16, 16], 'YTick', -15:3:15)

yticklabels = cell(size(h(3).YTick));
[yticklabels{:}]=deal('');
for ii = 1 : length(h(3).YTick)
    yticklabels{ii} = sprintf('%g', abs(h(3).YTick(ii)));
end
set(h(3), 'YTickLabel', yticklabels);


h_legend = legend(h(3), h_b, "Best, tied", "Best, unique", "Worst, unique");
set(h_legend, 'Location', 'Southwest', 'Box', 'off', 'NumColumns', 1,...
            'Interpreter', 'tex', 'Interruptible', 'on', 'FontSize', 14);

%%
addTileLabels(h, {'A', 'B', 'C'}, 'FontSize', 20, 'XOffset', -0.13);
exportgraphics(gcf, fullfile('Figures', 'Experimental EMG distribution.pdf'), "ContentType", "vector")