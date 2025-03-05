function labelHandles = addTileLabels(tileHandles, labels, varargin)
% ADDAXESLABELS Add labels to subplots at the upper-left corner outside of each axes
%
% labelHandles = addAxesLabels(tileHandles, labels, varargin)
%
% This function adds labels such as 'A', 'B', 'C', etc. to the upper-left
% corners just outside the axes of each subplot/tile. The labels will be properly
% aligned both horizontally and vertically.
%
% Inputs:
%   tileHandles - Array of axes handles (from nexttile or subplot)
%   labels      - Cell array of labels (e.g., {'A', 'B', 'C'}) or
%                 Character array for automatic labeling (e.g., 'ABC')
%
% Optional parameter/value pairs:
%   'FontSize'      - Label font size (default: 14)
%   'FontWeight'    - Label font weight (default: 'bold')
%   'FontColor'     - Label font color (default: 'k' [black])
%   'XOffset'       - X offset (negative moves left from axes) (default: -0.2)
%   'YOffset'       - Y offset (positive moves up from axes) (default: 0)
%
% Output:
%   labelHandles - Array of handles to the created text objects
%
% Example:
%   fig = figure;
%   t = tiledlayout(2, 2);
%   h(1) = nexttile; plot(rand(10,1));
%   h(2) = nexttile; plot(rand(10,1));
%   h(3) = nexttile; plot(rand(10,1));
%   h(4) = nexttile; plot(rand(10,1));
%   labelHandles = addAxesLabels(h, 'ABCD', 'FontSize', 16);
%
% See also: tiledlayout, nexttile, subplot, text

% Default parameters
defaultParams = struct(...
    'FontSize', 20, ...
    'FontName', 'Times New Roman', ...
    'FontWeight', 'bold', ...
    'FontColor', 'k', ...
    'XOffset', -0.1, ...
    'YOffset', 0 ...
);

% Parse optional inputs
p = inputParser;
p.addParameter('FontSize', defaultParams.FontSize);
p.addParameter('FontName', defaultParams.FontName);
p.addParameter('FontWeight', defaultParams.FontWeight);
p.addParameter('FontColor', defaultParams.FontColor);
p.addParameter('XOffset', defaultParams.XOffset);
p.addParameter('YOffset', defaultParams.YOffset);
p.parse(varargin{:});

params = p.Results;

% Convert character array to cell array for labels
if ischar(labels)
    labels = cellstr(labels(:))';
end

% Ensure we have enough labels
if length(labels) < length(tileHandles)
    error('Not enough labels provided for all tiles');
end

% Initialize output array
numTiles = length(tileHandles);
labelHandles = gobjects(numTiles, 1);

% Get positions of all axes in normalized coordinates
axesPos = zeros(numTiles, 4);
for i = 1:numTiles
    % Store each axes position
    axesPos(i,:) = get(tileHandles(i), 'Position');
end

% Find unique row positions and column positions for alignment
% (using the top-left corner of each axes for grouping)
yTop = axesPos(:,2) + axesPos(:,4); % y-coordinate of top edge
xLeft = axesPos(:,1);              % x-coordinate of left edge

% Round to handle floating-point precision issues
uniqueRows = unique(round(yTop, 4), 'stable');
uniqueCols = unique(round(xLeft, 4), 'stable');

% Add the labels to each axes
for i = 1:numTiles
    % Current axes and position
    ax = tileHandles(i);
    
    % Create text in normalized axes coordinates
    % Position is relative to the axes (0,0 is bottom-left, 1,1 is top-right)
    labelHandles(i) = text(ax, params.XOffset, 1 + params.YOffset, labels{i}, ...
        'Units', 'normalized', ...
        'FontSize', params.FontSize, ...
        'FontName', params.FontName, ...
        'FontWeight', params.FontWeight, ...
        'Color', params.FontColor, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'baseline');
end

% Now ensure alignment by grouping labels by rows and columns
% Organize tiles by row
rowGroups = cell(length(uniqueRows), 1);
for i = 1:numTiles
    rowIdx = find(abs(round(yTop(i), 4) - uniqueRows) < 1e-4, 1);
    rowGroups{rowIdx} = [rowGroups{rowIdx}, i];
end

% Organize tiles by column
colGroups = cell(length(uniqueCols), 1);
for i = 1:numTiles
    colIdx = find(abs(round(xLeft(i), 4) - uniqueCols) < 1e-4, 1);
    colGroups{colIdx} = [colGroups{colIdx}, i];
end

% Align labels horizontally (within same column)
for i = 1:length(colGroups)
    if length(colGroups{i}) > 1
        % Get all axes in this column
        tilesInThisCol = colGroups{i};
        
        % Get the positions in axes-normalized coordinates
        positions = zeros(length(tilesInThisCol), 2);
        for j = 1:length(tilesInThisCol)
            tileIdx = tilesInThisCol(j);
            pos = get(labelHandles(tileIdx), 'Position');
            positions(j,1:2) = pos(1:2);
        end
        
        % Find the leftmost position
        leftmostX = min(positions(:,1));
        
        % Update all labels in this column to use this x-position
        for j = 1:length(tilesInThisCol)
            tileIdx = tilesInThisCol(j);
            pos = get(labelHandles(tileIdx), 'Position');
            pos(1) = leftmostX;
            set(labelHandles(tileIdx), 'Position', pos);
        end
    end
end

% Align labels vertically (within same row)
for i = 1:length(rowGroups)
    if length(rowGroups{i}) > 1
        % Get all axes in this row
        tilesInThisRow = rowGroups{i};
        
        % Get the positions in axes-normalized coordinates
        positions = zeros(length(tilesInThisRow), 2);
        for j = 1:length(tilesInThisRow)
            tileIdx = tilesInThisRow(j);
            pos = get(labelHandles(tileIdx), 'Position');
            positions(j,1:2) = pos(1:2);
        end
        
        % Find the highest position
        highestY = max(positions(:,2));
        
        % Update all labels in this row to use this y-position
        for j = 1:length(tilesInThisRow)
            tileIdx = tilesInThisRow(j);
            pos = get(labelHandles(tileIdx), 'Position');
            pos(2) = highestY;
            set(labelHandles(tileIdx), 'Position', pos);
        end
    end
end

end