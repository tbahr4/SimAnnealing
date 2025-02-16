close all; clear; pause on;
t_exec = tic;

pauseDelay = 1;
enableIntermediatePlots = true;

startPos = [0.5 0.5];
tmax_alloc = 5;            % Max allocation time, assumes time is at most time to node 1


%% Spawn nodes
nNodes = 100;
nodes = SpawnNodes(nNodes, "Random");
% nodes = SpawnNodes(nNodes, "Groups", 4, 0.25);     % Group count, Node spacing


%% Plot initial nodes
figure
ax = gca;
hold(ax, "on");

if enableIntermediatePlots 
    plot(ax, startPos(1), startPos(2), '.g', 'MarkerSize', 20);
    plot_AddNodes(ax, nodes);
    plot_Format(ax);
    title(["Iteration 1"; "N = 0"; "T = 0"]);
    pause(pauseDelay);
end

% Precompute weights to each node
[startWeights, nodeWeights] = ComputeNodeWeights(startPos, nodes);


% Begin with base solution to node 1
nAllocs = 1;
best_solution = 1;         % Current best, accepted solution
best_cost = startWeights(1);


if enableIntermediatePlots 
    plot_AddPath(ax, nodes, startPos, best_solution);

    title(["Iteration 1"; "N = " + string(nAllocs); "T = " + string(best_cost)]);
    pause(pauseDelay);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Start allocation loop
iteration = 1;

while nAllocs < size(nodes,1)
    iteration = iteration + 1;
    proposed_solution = best_solution;      % Current solution, either add a node or optimize
    proposed_cost = best_cost;

    %% Add a new node if under-subscribed
    if proposed_cost <= tmax_alloc
        disp("Adding node N=" + string(nAllocs+1));
        nextIdx = nAllocs + 1;
        
        proposed_solution = [best_solution, nextIdx];
        proposed_cost = proposed_cost + nodeWeights(best_solution(end), nextIdx); % Add time from last node to new last node
        nAllocs = nAllocs + 1;

         % Plot proposed path
        if enableIntermediatePlots 
            plot(nodes.x([best_solution(end) nextIdx]), nodes.y([best_solution(end) nextIdx]), "Color", [1 0 0]);
        end
        
    end   

    % Update plot
    if enableIntermediatePlots 
        title(["Iteration " + string(iteration); "N = " + string(nAllocs); "T = " + string(proposed_cost)]);
        pause(pauseDelay);
    end

    %% Check if oversubscribed
    if proposed_cost > tmax_alloc
        disp("Optimizing solution N=" + string(nAllocs));
        initial_temp = 0.5 * max([max(startWeights, [], "all"), max(nodeWeights, [], "all")]);  % Initialize to half the edge length
        cooling_rate = 0.999;  % .95 original agressive
        [solution, cost, isValid] = optimize(startWeights, nodeWeights, ...
                                             proposed_solution, proposed_cost, ...
                                             tmax_alloc, initial_temp, cooling_rate);

        if isValid  % solution is valid
            if cost <= tmax_alloc
                best_solution = solution;
                best_cost = cost;
            else
                error("Provided unoptimal, yet valid solution. Investigate");
            end
        else
            % Take last solution
            break;
        end

        if enableIntermediatePlots 
            cla(ax);
            plot_AddNodes(ax, nodes);
            plot(ax, startPos(1), startPos(2), '.g', 'MarkerSize', 20);
            plot_Format(ax);
            title(["Iteration " + string(iteration); "N = " + string(nAllocs); "T = " + string(best_cost)]);
            plot_AddPath(ax, nodes, startPos, best_solution);
            pause(pauseDelay);
        end
    else
        % Accept solution
        disp("Accepted solution N=" + string(nAllocs));
        if enableIntermediatePlots 
            plot(nodes.x([best_solution(end) nextIdx]), nodes.y([best_solution(end) nextIdx]), "Color", [0 0 0]);
        end
        pause(pauseDelay);
        best_solution = proposed_solution;
        best_cost = proposed_cost;
    end

end

%% Final solution
cla(ax);
plot_AddNodes(ax, nodes);
plot(ax, startPos(1), startPos(2), '.g', 'MarkerSize', 20);
plot_Format(ax);
title(["Iteration " + string(iteration); "N = " + string(numel(best_solution)); "T = " + string(best_cost)]);
plot_AddPath(ax, nodes, startPos, best_solution);

disp("--------------------")
toc(t_exec);
disp("Solution: " + join(string(best_solution), ", "));
disp("Cost: " + string(best_cost));
disp("--------------------")




function [best_solution, best_cost, isValid] = optimize(startWeights, nodeWeights, ...
                                                        initial_order, initial_cost, ...
                                                        tmax_alloc, initial_temp, cooling_rate)
    % Simulated annealing

    current_solution = initial_order;   % Consider re-ordering by nearest neighbor to have a good start? Or add in prev. function by nearest neighbor! This is a great idea since adding after optimizing will always be poor
    current_cost = initial_cost;

    best_solution = current_solution;
    best_cost = current_cost;
    temperature = initial_temp;

    isValid = true; % Solution is valid
    while current_cost > tmax_alloc % Continue until minimally viable
        % TODO: Prioritize swaps that fix long jumps first?
        [incNodeIdxA, incNodeIdxB] = select_random_swap(current_solution);

        % Apply 2-opt swap
        new_solution = swap_nodes(current_solution, incNodeIdxA, incNodeIdxB);
        new_cost = calculate_tour_distance(new_solution, startWeights, nodeWeights);
        delta = new_cost - current_cost;

        % Accept based on annealing probability
        if delta < 0 || rand < exp(-delta / temperature)
            current_solution = new_solution;
            current_cost = new_cost;

            % Track best solution found
            if new_cost < best_cost
                best_solution = new_solution;
                best_cost = new_cost;
            end
        end

        % TODO: Fast cooling at first, then stabilize?
        temperature = temperature * cooling_rate;

        if temperature < 1e-6
            isValid = false;    % Solution not found
            break;
        end
    end


end


function [incNodeIdxA, incNodeIdxB] = select_random_swap(current_solution)
    N = numel(current_solution);    % To include starting edge

    % 1 indicates incoming edge to node at index 1
    incNodeIdxA = randi([1 N]);
    incNodeIdxB = incNodeIdxA;
    while incNodeIdxB == incNodeIdxA
        incNodeIdxB = randi([1 N]);
    end
end

function new_solution = swap_nodes(current_solution, incNodeIdxA, incNodeIdxB)
    % Performs 2-opt swap,
    % e.g. S-1-2-3-4-5-6, swap edges S-1 and 4-5
    %      S-4-3-2-1-5-6, reverse 
    
    % edge1 = [incNodeIdxA-1 incNodeIdxA];    % 0-1
    % edge2 = [incNodeIdxB-1 incNodeIdxB];    % 4-5

    % Reverse order
    first = min([incNodeIdxA incNodeIdxB]);
    second = max([incNodeIdxA incNodeIdxB]);

    % reverse first to second-1
    new_solution = [current_solution(1:first-1) ...
                    fliplr(current_solution(first:second-1)) ...
                    current_solution(second:end)];
end

function cost = calculate_tour_distance(solution, startWeights, nodeWeights)
    cost = 0;

    for nodeI = 1:numel(solution)
        currNode = solution(nodeI);

        if nodeI == 1
            cost = cost + startWeights(currNode);
        else
            prevNode = solution(nodeI-1);
            cost = cost + nodeWeights(prevNode, currNode);
        end
    end
end

