function plot_Format(ax)

xlim(ax, [0 1]);
ylim(ax, [0 1]);
xticks(ax, 0:.25:1);
yticks(ax, 0:.25:1);
xlabel(ax, "X");
ylabel(ax, "Y");
grid(ax, "on");