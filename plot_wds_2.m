function plot_wds_2(s,add_nodes)
figure
hold on; % Keep the plot open for multiple drawings
axis equal; % Ensure equal scaling for X and Y

% Plot the edges
for i = 1:length(s.edges.node_idx)
    edge = s.edges.node_idx{i}; % Get the indices of the nodes forming the edge
    x_coords = [s.nodes.X(edge(1)), s.nodes.X(edge(2))];
    y_coords = [s.nodes.Y(edge(1)), s.nodes.Y(edge(2))];
    
    plot(x_coords, y_coords, 'k-', 'LineWidth', 1.5); % Draw the edge
end

% Plot the nodes
if add_nodes==1
scatter(s.nodes.X, s.nodes.Y, 60, 'ro', 'filled'); % Red circles for nodes
end
% Label the nodes with their IDs
%for i = 1:length(s.nodes.ID)
%    text(s.nodes.X(i), s.nodes.Y(i), sprintf('%d', s.nodes.ID{i}), ...
%        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'FontSize', 10);
%end

hold off;


end