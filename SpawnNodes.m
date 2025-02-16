function nodes = AddNodes(nNodes, type, arg1, arg2)
    nodes = table('Size', [0, 3], ...
                  'VariableNames', ["index", "x", "y"], ...
                  'VariableTypes', repmat("double", 1, 3));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if type == "Random"

        maxIter = 100;
        for i=1:nNodes
            % Only spawn if not near others due to text
            nIter = 1;
            while nIter <= maxIter
                x = rand;
                y = rand;
    
                if ~any(pdist2([x y], [nodes.x nodes.y]) < .1)
                    break;
                end
                nIter = nIter + 1;
            end
    
            nodes(end+1,:) = {i, x, y};
        end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    elseif type == "Groups"
    
        groupCount = arg1;
        maxIter = 100;
        groupCenters = [];

        % Generate groups
        for groupI = 1:groupCount
            nIter = 1;
            while nIter <= maxIter
                x = rand;
                y = rand;
    
                if x < .1 || x > .9 || y < .1 || y > .9
                    continue;
                end
                
                if ~any(groupCenters)
                    break;
                end
                if ~any(pdist2([x y], [groupCenters(:,1) groupCenters(:,2)]) < .1)
                    break;
                end
                nIter = nIter + 1;
            end

            groupCenters = [groupCenters; x,y];
        end

        % Generate nodes
        groupI = 0;
        for i=1:nNodes
            %% Select group
            groupI = groupI + 1;
            if groupI > groupCount
                groupI = 1;
            end
            
            %% Sample node
            nIter = 1;
            while nIter <= maxIter
                x = groupCenters(groupI, 1) + (rand * arg2);
                y = groupCenters(groupI, 2) + (rand * arg2);

                if x < 0 || x > 1 || y < 0 || y > 1
                    continue;
                end
    
                if ~any(pdist2([x y], [nodes.x nodes.y]) < .1)
                    break;
                end
                nIter = nIter + 1;
            end

            nodes(end+1,:) = {i, x, y};
        end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else
        error("Invalid node spawn type");
    end
end