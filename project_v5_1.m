function project_v5_1

global d

d = epanet('network_2.inp');

x0 = 50 * ones(1,d.getLinkCount);
LB = 10 * ones(1,d.getLinkCount);
UB = 100 * ones(1,d.getLinkCount);

%length = 100 * ones(1,d.getLinkCount);
%d.setLinkLength(length);

x_opt = fminsearchbnd(@entropy, x0, LB, UB);
disp("Optimal diameter:");
disp(x_opt);

S = entropy(x_opt);
%list_pipe_data(d.getLinkNameID, x_opt, 'Diameters');
disp("Entropy:");
disp(S);

end

function list_pipe_data(dict, data, varname)
    fprintf('\n Data (%s):', varname)
    
    [dict_sorted, idx] = sort(dict); 
    data_sorted = data(idx); 
    for i = 1:length(dict)
        fprintf('\n\t %5s: %6.2f', dict_sorted{i}, data_sorted(i))
    end
    fprintf('\n\n')
end

function S = entropy(x)

    global d

    d.setLinkDiameter(x);
    d.solveCompleteHydraulics;

    % Datas from EPANET
    Flow_Rates = d.getLinkFlows; 
    Demands = d.getNodeBaseDemands;
    Demands = cell2mat(Demands);
    Num_Nodes = d.getNodeCount;
    Num_Links = d.getLinkCount;
    Num_Junctions = d.getNodeJunctionCount;
    Node_Names = d.getNodeNameID;
    Link_Names = d.getLinkNameID;
    Links = d.getLinkNodesIndex;
    Flow_Magnitudes = abs(Flow_Rates);
    Flow_Directions = sign(Flow_Rates);
    Junctions = d.getNodeJunctionIndex;

    % Links correction based on flow directions
    for i = 1:Num_Links
        if Flow_Directions(i) < 0
            Links(i, :) = flip(Links(i, :));
        end
    end

% FOR ALL NODES

    % Check Input and Output properties
    Nodes = unique(Links(:));
    Out_degree = histcounts(Links(:,1), [Nodes; max(Nodes) + 1]);
    In_degree = histcounts(Links(:,2), [Nodes; max(Nodes) + 1]);

    % Creating all necessary probability arrays
    p_Nodes = zeros(1,Num_Nodes);
    p_Weight = zeros(1,Num_Nodes);
    p_Links = zeros(1, Num_Links);
    Ss = zeros(1, Num_Nodes + 1);

    % Get all necessary preliminary node for every node
    for i = 1:Num_Nodes
    Node = Nodes(i);
    Input_Nodes{i} = Links(Links(:,2) == Node, 1);
    Output_Nodes{i} = Links(Links(:,1) == Node, 2);
    end

% Get TOTAL Input flow value
    Total_In = 0;
    Num_Inputs = 0;
    Inputs = [];
    for i = 1:Num_Nodes
        if (In_degree(i) == 0)
            Num_Inputs = Num_Inputs + 1;
            Inputs = [ Inputs , i ];
            Input_Flows = Flow_Magnitudes(Links(:,1) == i);
            for j = 1:Out_degree(i)
                Total_In = Total_In + Input_Flows(j);
            end
            if (Demands < 0)
                Total_In = Total_In + Demands(i);
            end
        end
    end

% Calculate Input Node probabilities
    Total_In_N = 0;
    for i = 1:Num_Inputs
        Total_In_N = 0;
        if (In_degree(Inputs(i)) == 0)
            Input_Flows = Flow_Magnitudes(Links(:,1) == Inputs(i));
            p_Links(Links(:,1) == Inputs(i)) = 1;
            for j = 1:Out_degree(Inputs(i))
                Total_In_N = Total_In_N + Input_Flows(j);
            end
            if (Demands < 0)
                Total_In_N = Total_In_N - Demands(Inputs(i));
            end
            p_Nodes(Inputs(i)) = Total_In_N / Total_In;
            p_Weight(Inputs(i)) = p_Nodes(Inputs(i));
        end
    end

% Display Node properties
    %fprintf(' Node | Out-Degree | Output Nodes       | In-Degree | Input Nodes\n');
    %fprintf('--------------------------------------------------------------------\n');
    
    %for i = 1:length(Nodes)
    %    outputStr = strjoin(string(Output_Nodes{i}), ' ');
    %    inputStr  = strjoin(string(Input_Nodes{i}),  ' ');
    %    fprintf('%5d | %10d | %-18s | %9d | %-16s\n', ...
    %        Nodes(i), Out_degree(i), outputStr, In_degree(i), inputStr);
    %end

% PREPROCESS JUNCTIONS

    Processable_Junctions = find(In_degree == 0);
    Processable_Junctions = Processable_Junctions(ismember(Processable_Junctions, Junctions));
    if (isempty(Processable_Junctions))
        for i = 1:Num_Junctions
            Processable = true;
            for j = 1:In_degree(i)
                if (ismember(Input_Nodes{i}(j),Junctions))
                    Processable = false;
                end
            end
            if (Processable)
                Processable_Junctions = [ Processable_Junctions, i ]; % Saving the index
            end
        end
    end

    Processed_Junctions = [];

% PROCESS JUNCTIONS
    % Data processing loop
    while ~isempty(Processable_Junctions)

        Current_Junction = Processable_Junctions(1);
        Processable_Junctions(1) = [];

        % Node probabilities
        Total_Outflow = 0;
        for i = 1:Num_Links
            if (Links(i,1) == Current_Junction)
                Total_Outflow = Total_Outflow + Flow_Magnitudes(i);
            end
        end
        if (Demands(Current_Junction) > 0)
            p_Nodes(Current_Junction) = Demands(Current_Junction) / (Total_Outflow + Demands(Current_Junction));
        else
            p_Nodes(Current_Junction) = - Demands(Current_Junction) / (Total_Outflow);
        end
       
        % Link probabilities -> All output of the nodes
        for i = 1:Num_Links
            if (Links(i,1) == Current_Junction)
                if (Demands(Current_Junction) > 0)
                    p_Links(i) = Flow_Magnitudes(i) / (Total_Outflow + Demands(Current_Junction));
                else
                    p_Links(i) = Flow_Magnitudes(i) / (Total_Outflow);
                end
            end
        end

        % Calculate Entropy for the nodes
        s_temp = 0;
        Link_index = find(Links(:,1) == Current_Junction);
        for i = 1:Out_degree(Current_Junction)
            s_temp = s_temp + p_Links(Link_index(i)) * log2(p_Links(Link_index(i)));
        end
        if (Demands(Current_Junction) > 0)
            s_temp = s_temp + p_Nodes(Current_Junction) * log2(p_Nodes(Current_Junction));
        end
        

        % Input probabilities for each Node
        for i = 1:In_degree(Current_Junction)
            Link_index2 = Links(:,2) == Current_Junction & Links(:,1) == Input_Nodes{Current_Junction}(i);
            p_Weight(Current_Junction) = p_Weight(Current_Junction) + p_Nodes(Input_Nodes{Current_Junction}(i)) * p_Links(Link_index2);
        end

        Ss(Current_Junction) = - p_Weight(Current_Junction) * s_temp;


        % Add to processed nodes
        Processed_Junctions = [ Processed_Junctions, Current_Junction ];

        % Add new processable nodes
        for i = 1:Num_Junctions
            Processable = true;
            for j = 1:length(Input_Nodes{i})
                if ((ismember(Input_Nodes{i}(j), Junctions)) && (~ismember(Input_Nodes{i}(j), Processed_Junctions)))
                    Processable = false;
                    break;
                end
            end
            if (Processable && ~ismember(Junctions(i), Processable_Junctions) && ~ismember(Junctions(i), Processed_Junctions))
                Processable_Junctions = [ Processable_Junctions, Junctions(i) ];
            end
        end

        % Show Processed Nodes
        %disp(Node_Names(Processed_Junctions));

    end

    %disp(Link_Names);
    %disp("p Links:")
    %disp(p_Links);
    %disp(Node_Names);
    %disp("p Nodes:")
    %disp(p_Nodes);
    %disp("Flows:");
    %disp(Flow_Rates);

    % Calculate S0
    Ss(length(Nodes) + 1) = 0;
    for i = 1:Num_Nodes
        if (In_degree(i) == 0)
            if p_Nodes(i) > 0
                Ss(Num_Nodes + 1) = Ss(Num_Nodes + 1) - p_Nodes(i) * log2(p_Nodes(i));
            end
        end
    end

    % Summarizing up the calculated Ss
    %list_pipe_data(Link_Names, Flow_Rates, 'Flows');
    %list_pipe_data(Node_Names, p_Nodes, 'Nodes');  
    S = -sum(Ss);

end
