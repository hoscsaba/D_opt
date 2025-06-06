function hFig = plot_wds_4( ...
    s, ...
    add_nodes, ...
    add_node_labels, ...
    add_edge_labels, ...
    edge_vals, ...
    edge_vels, ...
    fignum, ...
    ylabel_text, ...
    vmin, ...
    vmax)
% PLOT_WDS_3   Plot a graph with optional node markers/labels, colored edges, 
%              and flow‐direction arrows centered on each edge.
%
%   hFig = plot_wds_3( ...
%       s, ...                % struct with fields:
%                            %   – s.nodes.X, s.nodes.Y : [N×1] node coordinates
%                            %   – s.nodes.ID          : {N×1} cell‐array of node IDs
%                            %   – s.edges.ID          : {M×1} cell‐array of edge IDs
%                            %   – s.edges.node_idx    : {M×1} cell‐array; each cell = [i j]
%       add_nodes, ...        % (0 or 1) if 1, plot nodes as filled red circles
%       add_node_labels, ...  % (0 or 1) if 1, place text labels at each node
%       add_edge_labels, ...  % (0 or 1) if 1, draw edge‐ID text at each midpoint
%       edge_vals, ...        % [M×1] numeric values for edge‐coloring
%       edge_vels, ...        % [M×1] “velocity” per edge: 
%                            %   >0→ arrow points i→j; 
%                            %   <0→ arrow points j→i; 
%                            %    0→ no arrow
%       fignum, ...           % figure number
%       ylabel_text, ...      % string for colorbar label
%       vmin, vmax)           % color‐scale limits (scalars)
%
%   Example:
%       % Suppose s.edges.node_idx = {[1 2],[2 3],[1 3]};
%       % edge_vals = [0.2;0.8;0.5];
%       % edge_vels = [ 1; -0.5; 0 ];
%       plot_wds_3(s,1,1,1, edge_vals, edge_vels, 2, 'Weight', 0, 1);
%
%   Notes:
%     • If all entries of edge_vals are equal, colormap collapses to single color.
%     • Arrow‐length is chosen as 20% of the edge’s length. 
%     • Arrow is centered on midpoint; no manual offset needed.
%     • If edge_vels(i)==0, no arrow is drawn on that edge.
%

    % -------------------------------------------------------------------------
    % 1) INPUT CHECKS
    % -------------------------------------------------------------------------
    if nargin < 10
        error(['plot_wds_3 requires ten inputs: ', ...
               '(s, add_nodes, add_node_labels, add_edge_labels, edge_vals, ', ...
               'edge_vels, fignum, ylabel_text, vmin, vmax).']);
    end

    M = numel(s.edges.ID);
    if numel(edge_vals) ~= M
        error('edge_vals must be length %d (number of edges).', M);
    end
    if numel(edge_vels) ~= M
        error('edge_vels must be length %d (number of edges).', M);
    end

    % -------------------------------------------------------------------------
    % 2) CREATE FIGURE & SETUP
    % -------------------------------------------------------------------------
    hFig = figure(fignum);
    clf(hFig);
    hold on;
    axis equal;
    
    cmap = jet(256);
    
    % Normalize edge_vals into indices [1..256]
    if vmax > vmin
        scaled = round( (edge_vals - vmin) ./ (vmax - vmin) * 255 ) + 1;
        scaled(scaled < 1)   = 1;
        scaled(scaled > 256) = 256;
    else
        % all edge_vals identical → pick middle index
        scaled = ones(M,1) * 128;
    end

    % -------------------------------------------------------------------------
    % 3) PLOT EACH EDGE (LINE + OPTIONAL EDGE‐ID + CENTERED ARROW)
    % -------------------------------------------------------------------------
    for i = 1:M
        idx_pair = s.edges.node_idx{i};  % [node_i, node_j]
        ni = idx_pair(1);
        nj = idx_pair(2);

        x_i = s.nodes.X(ni);
        y_i = s.nodes.Y(ni);
        x_j = s.nodes.X(nj);
        y_j = s.nodes.Y(nj);

        % 3a) Choose edge color from colormap
        cidx = scaled(i);
        edge_color = cmap(cidx, :);

        % 3b) Draw the line for this edge
        plot([x_i, x_j], [y_i, y_j], '-', ...
             'Color',     edge_color, ...
             'LineWidth', 1.5);

        % 3c) If requested, place the edge ID at the (offset) midpoint
        if add_edge_labels == 1
            xm = 0.5*(x_i + x_j);
            ym = 0.5*(y_i + y_j);
            dx_e = x_j - x_i;
            dy_e = y_j - y_i;
            L_e = hypot(dx_e, dy_e);
            if L_e > 0
                off = 0.02;              
                ux_p = -dy_e / L_e;     
                uy_p =  dx_e / L_e;
            else
                ux_p = 0; uy_p = 0;
            end
            text( xm + off*ux_p, ...
                  ym + off*uy_p, ...
                  s.edges.ID{i}, ...
                  'FontSize', 9, ...
                  'HorizontalAlignment', 'center', ...
                  'VerticalAlignment', 'middle', ...
                  'BackgroundColor', 'w', ...
                  'Margin', 1);
        end

        % 3d) If edge_vels(i) ≠ 0, draw a small arrow at edge‐midpoint
        v = edge_vels(i);
        if v ~= 0
            % Full vector from i→j
            dx_full = x_j - x_i;
            dy_full = y_j - y_i;
            L_full = hypot(dx_full, dy_full);
            if L_full == 0
                continue;  % zero‐length edge → skip arrow
            end

            % Determine direction: 
            %   if v>0, arrow i→j; if v<0, arrow j→i
            if v > 0
                u_x = dx_full / L_full;
                u_y = dy_full / L_full;
            else
                u_x = -dx_full / L_full;
                u_y = -dy_full / L_full;
            end

            % Midpoint of the edge
            xm = 0.5*(x_i + x_j);
            ym = 0.5*(y_i + y_j);

            % Arrow length = 20% of full‐edge length
            lam = 0.20 * L_full;

            % Place arrow so it’s centered at (xm, ym):
            %   tail at (xm - 0.5*lam*u_x, ym - 0.5*lam*u_y)
            x_tail = xm - 0.5*lam*u_x;
            y_tail = ym - 0.5*lam*u_y;
            dx_arr  = lam * u_x;
            dy_arr  = lam * u_y;

            % Draw arrow using quiver with no autoscale
            quiver( x_tail, y_tail, dx_arr, dy_arr, 0, ...
                    'Color',       edge_color, ...
                    'LineWidth',   1.5, ...
                    'MaxHeadSize', 2.0, ...
                    'AutoScale',   'off');
        end
    end

    % -------------------------------------------------------------------------
    % 4) PLOT NODES (optional) AND NODE LABELS (optional)
    % -------------------------------------------------------------------------
    if add_nodes == 1
        scatter(s.nodes.X, s.nodes.Y, 60, 'ro', 'filled');
    end

    if add_node_labels == 1
        for k = 1:numel(s.nodes.ID)
            text( s.nodes.X(k), ...
                  s.nodes.Y(k), ...
                  sprintf('%s', s.nodes.ID{k}), ...
                  'VerticalAlignment',   'bottom', ...
                  'HorizontalAlignment', 'right',  ...
                  'FontSize',           10);
        end
    end

    % -------------------------------------------------------------------------
    % 5) ADD COLORBAR FOR EDGE‐VALUE → COLOR MAPPING
    % -------------------------------------------------------------------------
    colormap(cmap);
    cb = colorbar;
    caxis([vmin, vmax]);
    ylabel(cb, ylabel_text);

    hold off;
end
