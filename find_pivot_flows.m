function pivot_edge_id=find_pivot_flows(DO_PLOT)
    global wds

    % For cycle and path analysis, use undrirected graph
    edgeNames=wds.edges.ID';
    G=graph(wds.edges.node_from_ID,wds.edges.node_to_ID,table(edgeNames),wds.nodes.ID');
    if DO_PLOT==1
        plot(G,'EdgeLabel',G.Edges.edgeNames);
    end
    %% Warning: Matlab's constructor reorders edges! We build a vocabulary between the two edges lists.
    %% graph_edge_idx(i)=j -> the ith edge in wds.graph is the jth edge in Epanet input list
    for graph_edge_idx=1:wds.N_e
        name = G.Edges.edgeNames{graph_edge_idx};
        is_found=0;
        for i=1:wds.N_e
            if strcmp(name,wds.edges.ID{i})==1
                epanet_edge_idx(graph_edge_idx)=i;
                is_found=1;
                break;
            end
        end
        if is_found==0
            disp(name);
            error("Building epanet_edge_idx failed, cannot find edge!")
        end
    end

    % Count endnodes (nodes with only one edge, degree=1)
    deg=degree(G);
    is_endnode=(deg==1);
    idx_of_endnode=find(is_endnode);

    % Build paths between endnodes
    N_nodes_r1=length(idx_of_endnode);
    for i=1:N_nodes_r1-1
        [paths{i},d{i},edgepaths{i}] = shortestpath(G,idx_of_endnode(end),idx_of_endnode(i));
    end

    % Build cycles
    [cycles,edgecycles] = cyclebasis(G);

    % Define pivot flows, use pipe with largest diameter
    pivot_edge_id=[];
    D=wds.edges.pipe.diameter;
    is_pipe=wds.edges.is_pipe;
    is_pivot=zeros(size(is_pipe));

    Nr=length(edgepaths);
    for i=1:Nr
        idx=epanet_edge_idx(edgepaths{i});
        %D_tmp=D(idx).*is_pipe(idx).*(1-is_pivot(idx));
        D_tmp=D(idx).*(1-is_pivot(idx));
        [val,idx_tmp]=max(D_tmp);
        is_pivot(idx(idx_tmp))=1;
        pivot_edge_id=[pivot_edge_id; idx(idx_tmp)];
        %fprintf('\n Path #%d: pivot_edge=%d',i,idx_tmp);
        %fprintf('\n Edges (id, D):');
        %edgecycles{i}
        %D(edgecycles{i})
    end

    Nc=length(edgecycles);
    for i=1:Nc
        idx=epanet_edge_idx(edgecycles{i});
        %D_tmp=D(idx).*is_pipe(idx).*(1-is_pivot(idx));
        D_tmp=D(idx).*(1-is_pivot(idx));
        [val,idx_tmp]=max(D_tmp);
        is_pivot(idx(idx_tmp))=1;
        pivot_edge_id=[pivot_edge_id; idx(idx_tmp)];

        %fprintf('\n Cycle #%d: pivot_edge=%s (idx=%d)',i,wds.edges.ID{idx(idx_tmp)},idx(idx_tmp));
        %fprintf('\n Edges (id, D):');
    end

    % Check if pivots are unique
    if length(pivot_edge_id)~=length(unique(pivot_edge_id))
        pivot_edge_id
        error("ERROR!!! pivot_edge_id includes multiple edges!!!");
    end

    if DO_PLOT>0
        fprintf("\n Found pivot edges.");
        fprintf("\n\t Number of edges       : %2d",length(wds.edges.ID));
        fprintf("\n\t Number of vertices    : %2d (all nodes, including rank1-nodes)",length(wds.nodes.ID));
        fprintf("\n\t Number of rank1-nodes : %2d (nodes with prescribed pressure)",N_nodes_r1);
        fprintf("\n\t Number of paths       : %2d",Nr);
        fprintf("\n\t Number of cycles      : %2d",Nc);
        pc=length(pivot_edge_id)/length(wds.edges.ID)*100.;
        fprintf("\n\t Number of pivots      : %2d (%4.1f%% of all edges)",length(pivot_edge_id),pc);
        fprintf("\n\t(Number of pivots      : #edges - #nodes + #rank_1 = %g - %g + %g = %g)",...
            wds.N_e,length(wds.nodes.ID),N_nodes_r1,wds.N_e-length(wds.nodes.ID)+N_nodes_r1);

        % Plot
        if (Nr>0)
            for k = 1:min(3,Nr)
                figure(k)
                highlight(plot(G,'EdgeLabel',G.Edges.edgeNames),paths{k},'Edges',edgepaths{k},'EdgeColor','r','NodeColor','r','LineWidth',3)
                %highlight(plot(G),paths{k},'Edges',edgepaths{k},'EdgeColor','r','NodeColor','r')
                title("Path " + k+", pivot: "+wds.edges.ID(pivot_edge_id(k)));
            end
        end
        if Nc>0
            for k = Nr+1:Nr+min(3,Nc)
                figure(k)
                highlight(plot(G,'EdgeLabel',G.Edges.edgeNames),cycles{k-Nr},'Edges',edgecycles{k-Nr},'EdgeColor','r','NodeColor','r','LineWidth',3)
                %highlight(plot(G),cycles{k-Nr},'Edges',edgecycles{k-Nr},'EdgeColor','r','NodeColor','r')
                title("Cycle "+(k-Nr)+", pivot: " + wds.edges.ID(pivot_edge_id(k)));
            end
        end
    end
end
