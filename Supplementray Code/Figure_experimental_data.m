% Figure experimenal data
clear
close all

% background noise data
Vpp = importdata("A05_Background_Noise_MEP.mat");


%%
fig = figure('Color', [1 1 1]);
figWidth = 15;
figHeigth = 15;
%
set(gcf,'unit','centimeters','position',[1, 2, figWidth, figHeigth],...
    'PaperUnits','centimeters','PaperOrientation','portrait',...
    'PaperSize',[figWidth, figHeigth]);

%
histogram(Vpp, 'Normalization', 'pdf', 'EdgeColor', 'none')
hold on

Dtrain = Vpp;

%
% GEV fit
gev_parameter = mygevfit(Dtrain);


% lognormal fit
pd_lgn = fitdist(Dtrain', 'Lognormal');
lgn_parameter = pd_lgn.ParameterValues;

% normal fit
pd_norm = fitdist(Dtrain', 'Normal');
norm_parameter = pd_norm.ParameterValues;

% Gamma distribution
pd_gamma = fitdist(Dtrain', "Gamma");
gamma_parameter = pd_gamma.ParameterValues;


%
X = linspace(0, 0.025, 2000);

% Lognormal
bp = lgn_parameter;
plot(X, lognpdf(X, bp(1), bp(2)), 'LineWidth', 2, 'LineStyle', '--');

% Gamma
bp = gamma_parameter;
plot(X, gampdf(X, bp(1), bp(2)), 'LineWidth', 2, 'LineStyle', ':');

% GEV
bp = gev_parameter;
plot(X, gevpdf(X, bp(1), bp(2), bp(3)), 'LineWidth', 2, 'LineStyle', '-');

% Normal
bp = norm_parameter;
plot(X, normpdf(X, bp(1), bp(2)), 'LineWidth', 2, 'LineStyle', '-.');


% legend
legend({'', 'Log-normal distribution', 'Gamma distribution', 'GEV distribution', 'Normal distribution'}, ...
       'Box', 'off', 'Interpreter', 'latex', 'FontSize', 16)


set(gca, 'XGrid', 'on', 'YGrid', 'on', 'Box', 'on', 'XMinorGrid', 'on', ...
    'TickDir', 'both', 'FontSize', 14, 'TickLabelInterpreter', 'latex', ...
    'XLim', [-0.001, 0.025])


xlabel('Peak-to-peak voltage $V_\textrm{pp}$ (mV)', 'Interpreter', 'latex')
ylabel('Probability Density', 'Interpreter', 'latex')

exportgraphics(fig, 'Experimental Baseline Noise.pdf', 'ContentType', 'vector')
