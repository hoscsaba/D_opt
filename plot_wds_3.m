function hFig=plot_wds_3(s, add_nodes, add_node_labels, add_edge_labels,edge_vals,fignum,ylabel_text,vmin,vmax)
% PLOT_WDS_2   Plot a graph with optional node markers/labels and colored edges.
%
%   plot_wds_2(s, add_nodes, add_node_labels, edge_vals)
%
%   Inputs:
%     - s : struct with fields
%           • s.nodes.X, s.nodes.Y : [N×1] vectors of node coordinates
%           • s.nodes.ID          : {N×1} cell-array of node IDs (strings)
%           • s.edges.ID          : {M×1} or [M×1] array of edge IDs (ignored here)
%           • s.edges.node_idx    : {M×1} cell-array; each cell is [i j] indicating
%                                  an edge between node i and node j.
%
%     - add_nodes        : (0 or 1) if 1, plot nodes as filled red circles.
%     - add_node_labels  : (0 or 1) if 1, place text labels at each node.
%     - edge_vals        : [M×1] vector of numeric values, one per edge. Edges
%                          will be colored according to these values.
%
%   Example:
%       % Suppose s.edges.node_idx = {[1 2], [2 3], [1 3]};
%       % and edge_vals = [0.2; 0.8; 0.5];
%       plot_wds_2(s, 1, 1, edge_vals);
%
%   Notes:
%     • If all entries of edge_vals are equal, colormap will collapse to a single
%       color (no gradient).
%     • You can change the colormap by modifying the call to "cmap = jet(256);" below.
%

    % Check inputs
    if nargin < 4
        error('plot_wds_2 requires four inputs: (s, add_nodes, add_node_labels, edge_vals).');
    end
    M = length(s.edges.ID);
    if numel(edge_vals) ~= M
        error('edge_vals must be a vector of length equal to the number of edges (%d).', M);
    end

    % Create figure
    hFig=figure(fignum);
    hold on;
    axis equal;

    % Build a colormap (e.g. 256 colors from 'jet')
    cmap = jet(256);

    % Normalize edge_vals into [1, 256]
    %vmin = min(edge_vals);
    %vmax = max(edge_vals);
    if vmax > vmin
        % Scale so that vmin→1 and vmax→256
        scaled = round( (edge_vals - vmin) ./ (vmax - vmin) * 255 ) + 1;
    else
        % All edge_vals are the same, pick middle index
        scaled = ones(M,1) * 128;
    end

    % Plot each edge with its corresponding color
    for i = 1:M
        idx_pair = s.edges.node_idx{i};     % [node_i, node_j]
        x_coords = [s.nodes.X(idx_pair(1)), s.nodes.X(idx_pair(2))];
        y_coords = [s.nodes.Y(idx_pair(1)), s.nodes.Y(idx_pair(2))];

        color_idx = scaled(i);
        edge_color = cmap(color_idx, :);

        plot(x_coords, y_coords, '-', 'Color', edge_color, 'LineWidth', 1.5);
    
    % If requested, place the edge ID at the midpoint
        if add_edge_labels == 1
            xm = mean(x_coords);
            ym = mean(y_coords);
            % Offset the text slightly perpendicular to the edge direction
            dx = x_coords(2) - x_coords(1);
            dy = y_coords(2) - y_coords(1);
            % Compute a small perpendicular offset (normalized)
            L = sqrt(dx^2 + dy^2);
            if L > 0
                off = 0.02;  % adjust this for a bigger/smaller offset
                ux = -dy / L;  % unit‐vector perpendicular
                uy =  dx / L;
            else
                ux = 0; uy = 0;
            end
            text(xm + off*ux, ym + off*uy, s.edges.ID{i}, ...
                 'FontSize', 9, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                 'BackgroundColor', 'w', 'Margin', 1);
        end
    end

    % If requested, overlay nodes as red circles
    if add_nodes == 1
        scatter(s.nodes.X, s.nodes.Y, 60, 'ro', 'filled');
    end

    % If requested, add node labels
    if add_node_labels == 1
        for i = 1:numel(s.nodes.ID)
            text( ...
                s.nodes.X(i), ...
                s.nodes.Y(i), ...
                sprintf('%s', s.nodes.ID{i}), ...
                'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'right', ...
                'FontSize', 10 ...
            );
        end
    end

    % Add a colorbar to indicate mapping from edge_vals → colors
    colormap(cmap);
    cb = colorbar;
    caxis([vmin, vmax]);
    ylabel(cb, ylabel_text);

    hold off;
end
