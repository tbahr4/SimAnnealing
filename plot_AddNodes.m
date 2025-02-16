function plot_AddNodes(ax, nodes)

plot(ax, nodes.x, nodes.y, '.r', 'MarkerSize', 10);
for i=1:size(nodes,1)
    text(ax, nodes.x(i), nodes.y(i), string(nodes.index(i)), 'FontSize', 10);
end