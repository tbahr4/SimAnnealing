function plot_AddPath(ax, nodes, startPos, order)

xs = zeros(1, numel(order)+1);
ys = zeros(1, numel(order)+1);

% Base case, path to first order node (assumed)
xs(1) = startPos(1);
ys(1) = startPos(2);

% Add order of nodes
xs(2:end) = nodes.x(order);
ys(2:end) = nodes.y(order);

% Plot path
plot(ax, xs, ys, "black");