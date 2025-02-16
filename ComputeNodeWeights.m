function [startWeights, weights] = ComputeNodeWeights(posStart, nodes)
% Returns NxM matrix specifying weight(time) from node Ni to node Mi

% Just let weights be the actual distance
startWeights = pdist2(posStart, [nodes.x nodes.y]);
weights = pdist2([nodes.x nodes.y], [nodes.x nodes.y]);

