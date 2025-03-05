function addFigureLabel(figHandle, axesHandle, LabelString, LabelSize, horziAdjust, vertiAdjust)
% This function is to add labels to each subplot in a figure object.
% Input:
% figHandle - the created figure window object
% axesHandle - the axes handle (check axes.OuterPosition)
% LabelString - label string
% LabelSize - the font size
% Note that this function should be used after all subplots are ready.
% 
% Author: Ke Ma, @21/12/2023
% University of Cambridge
%
if nargin < 5
    horziAdjust = 0;
    vertiAdjust = 0;
elseif nargin < 6
    vertiAdjust = 0;
end


%% main function
% define the position of the label axes
axesPosition = axesHandle.InnerPosition;
% axesPosition = tightPosition(axesHandle);
leftPosition = axesPosition(1) + horziAdjust;
bottomPosition = axesPosition(2) + axesPosition(4) + vertiAdjust;

% create the axes  
ax_1 = axes(figHandle, 'Position', [leftPosition, bottomPosition, 0.08, 0.05], 'Clipping', 'off', 'Box', 'off');
axis(ax_1,'off');
axis(ax_1, [0,1,-1,0]);
text(ax_1, 0, -1, ['\textbf{', LabelString, '}'], ...
    'Interpreter', 'Latex', 'FontSize', LabelSize, ...
    'HorizontalAlignment', 'Left', 'VerticalAlignment', 'cap');

% % annotation
% t = annotation("textbox");
% t.FontSize = 12;
% t.String = 'A';
% t.Position = [leftPosition, bottomPosition, 0.08, 0.05];
% t.EdgeColor = [1, 1, 1];


end