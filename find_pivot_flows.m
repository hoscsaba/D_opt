function pivot_edge_idx=find_pivot_flows(DO_PLOT,method)
global wds
global edgepaths edgecycles N_nodes_r1 epanet_edge_idx
global DEBUG

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

if method==0
    % Define pivot flows, use pipe with largest diameter
    pivot_edge_idx=[];
    D=wds.edges.diameter;

    is_pivot    =zeros(size(wds.edges.ID));
    is_forbidden=zeros(size(wds.edges.ID));

    % assumed rank of Rs
    Nr=length(edgepaths);
    for i=1:Nr
        idx=epanet_edge_idx(edgepaths{i});
        %D_tmp=D(idx).*(1-is_pivot(idx)).*(1-is_forbidden(idx));
        D_tmp=D(idx).*(1-is_pivot(idx));
        [val,idx_tmp]=max(D_tmp);

        pivot_edge_idx=[pivot_edge_idx; idx(idx_tmp)];
        is_pivot(idx(idx_tmp))=1;
        %fprintf('\n Path #%d/%d: pivot_edge=%d',i,Nr,idx_tmp);
        %fprintf('\n Edges (id, D):');
        %wds.edges.ID{idx}
    end

    Nc=length(edgecycles);
    for i=1:Nc
        idx=epanet_edge_idx(edgecycles{i});
        D_tmp=D(idx).*(1-is_pivot(idx));
        [val,idx_tmp]=max(D_tmp);
        pivot_edge_idx=[pivot_edge_idx; idx(idx_tmp)];
        is_pivot(idx(idx_tmp))=1;

        %fprintf('\n Cycle #%d/%d: pivot_edge=%s (idx=%d)',i,Nc,wds.edges.ID{idx(idx_tmp)},idx(idx_tmp));
        %fprintf('\n Edges (id, D):');
        %wds.edges.ID{idx}
    end


    DEBUG=0;

    if pivot_objective(pivot_edge_idx)>0
        pivot_edge_idx'
        fprintf("\n Naive pivot search filed. Starting optimization...");
        intcon = 1:1:length(pivot_edge_idx);
        A = [];
        b = [];
        Aeq = [];
        beq = [];
        lb = ones(size(pivot_edge_idx));
        ub = length(wds.edges.ID)*ones(size(pivot_edge_idx));
        nonlcon = [];
        %options = optimoptions('ga','PlotFcn', @gaplotbestf,'InitialPopulation',pivot_edge_idx','MaxStallGenerations',500,'MaxGenerations',1000);
        %options = optimoptions('ga','PlotFcn', @gaplotbestf,'MaxStallGenerations',500,'MaxGenerations',1000);
        popsize=100;
        for i=1:popsize
            ini(i,:)=pivot_edge_idx';
        end
        options = optimoptions('ga','PlotFcn', @gaplotbestf,'MutationFcn',@MyMutation,'InitialPopulation',ini,'PopulationSize',popsize,...
            'MaxStallGenerations',50, 'MaxGenerations',100);
        [x,fval,exitflag,output] = ga(@pivot_objective,length(pivot_edge_idx),A,b,Aeq,beq,lb,ub,nonlcon,intcon,options)
        pivot_edge_idx=x;
    end

    is_pivot=zeros(size(wds.edges.ID));
    for i=1:length(pivot_edge_idx)
        is_pivot(i)=1;
    end

    % Check if pivots are unique
    if length(pivot_edge_idx)~=length(unique(pivot_edge_idx))
        pivot_edge_idx
        error("ERROR!!! pivot_edge_idx includes multiple edges!!!");
    end

    if DO_PLOT>0
        fprintf("\n Found pivot edges, method=0 (naive + GA)");
        fprintf("\n\t Number of edges       : %2d",length(wds.edges.ID));
        fprintf("\n\t Number of vertices    : %2d (all nodes, including rank1-nodes)",length(wds.nodes.ID));
        fprintf("\n\t Number of rank1-nodes : %2d (nodes with prescribed pressure)",N_nodes_r1);
        fprintf("\n\t Number of paths       : %2d",Nr);
        fprintf("\n\t Number of cycles      : %2d",Nc);
        pc=length(pivot_edge_idx)/length(wds.edges.ID)*100.;
        fprintf("\n\t Number of pivots      : %2d (%4.1f%% of all edges)",length(pivot_edge_idx),pc);
        fprintf("\n\t(Number of pivots      : #edges - #nodes + #rank_1 = %g - %g + %g = %g)",...
            wds.N_e,length(wds.nodes.ID),N_nodes_r1,wds.N_e-length(wds.nodes.ID)+N_nodes_r1);
        num_of_vars=length(wds.edges.ID)+length(wds.nodes.ID);
        num_of_vars2=length(wds.edges.ID);
        fprintf("\n\t Number of unknown without pivoting : %g",num_of_vars);
        fprintf("\n\t Number of unknown with    pivoting : %g, %g%%",num_of_vars2,num_of_vars2/num_of_vars*100);

        % Plot a few of the cycles and paths...
        if (Nr>0)
            for k = 1:min(3,Nr)
                figure(k)
                highlight(plot(G,'EdgeLabel',G.Edges.edgeNames),paths{k},'Edges',edgepaths{k},'EdgeColor','r','NodeColor','r','LineWidth',3)
                %highlight(plot(G),paths{k},'Edges',edgepaths{k},'EdgeColor','r','NodeColor','r')
                title("Path " + k+", pivot: "+wds.edges.ID(pivot_edge_idx(k)));
            end
        end
        if Nc>0
            for k = Nr+1:Nr+min(3,Nc)
                figure(k)
                highlight(plot(G,'EdgeLabel',G.Edges.edgeNames),cycles{k-Nr},'Edges',edgecycles{k-Nr},'EdgeColor','r','NodeColor','r','LineWidth',3)
                %highlight(plot(G),cycles{k-Nr},'Edges',edgecycles{k-Nr},'EdgeColor','r','NodeColor','r')
                title("Cycle "+(k-Nr)+", pivot: " + wds.edges.ID(pivot_edge_idx(k)));
            end
        end
    end
end

if method==1
    T = minspantree(G);
    pivot_edge_idx=[]; graph_idx=[];
    for ii=1:height(G.Edges)
        if 0==sum(strcmp(G.Edges.edgeNames{ii},T.Edges.edgeNames))
            graph_idx=[graph_idx;ii];
            pivot_edge_idx=[pivot_edge_idx;epanet_edge_idx(ii)];
        end
    end

    % These are only the cycles, we need to add paths pivot flows
    % Find rank-1 nodes
    
    for i=1:length(wds.nodes.type)
        if wds.nodes.type(i)~=0
            for j=1:length(wds.edges.ID)
                if 1==strcmp(wds.nodes.ID{i},wds.edges.node_from_ID{j})...
                        || 1==strcmp(wds.nodes.ID{i},wds.edges.node_to_ID{j})
                    pivot_edge_idx=[pivot_edge_idx;j];
                    
                    for k=1:length(G.Edges.edgeNames)
                        if 1==strcmp(wds.edges.ID{j},G.Edges.edgeNames{k})
                            graph_idx=[graph_idx;k];
                        end
                    end
                    break
                end
            end
        end
    end

    % This is important: the last one must be removed.
    graph_idx=graph_idx(1:end-1);
    pivot_edge_idx=pivot_edge_idx(1:end-1);

    if DO_PLOT>0
        %figure(100)
        %p = plot(G);
        %highlight(p,T);

        figure(101)
        p = plot(G);
        highlight(p,'Edges',graph_idx,'EdgeColor','r','NodeColor','r','LineWidth',3)
        %highlight(plot(G,'EdgeLabel',G.Edges.edgeNames),'Edges',graph_idx,'EdgeColor','r','NodeColor','r','LineWidth',3)

        wds.edges.ID(pivot_edge_idx);

        fprintf("\n Found pivot edges, method=1 (spanning tree)");
        fprintf("\n\t Number of edges       : %2d",length(wds.edges.ID));
        fprintf("\n\t Number of vertices    : %2d (all nodes, including rank1-nodes)",length(wds.nodes.ID));
        fprintf("\n\t Number of rank1-nodes : %2d (nodes with prescribed pressure)",N_nodes_r1);
        %fprintf("\n\t Number of paths       : %2d",Nr);
        %fprintf("\n\t Number of cycles      : %2d",Nc);
        pc=length(pivot_edge_idx)/length(wds.edges.ID)*100.;
        fprintf("\n\t Number of pivots      : %2d (%4.1f%% of all edges)",length(pivot_edge_idx),pc);
        fprintf("\n\t(Number of pivots      : #edges - #nodes + #rank_1 = %g - %g + %g = %g)",...
            wds.N_e,length(wds.nodes.ID),N_nodes_r1,wds.N_e-length(wds.nodes.ID)+N_nodes_r1);
        num_of_vars=length(wds.edges.ID)+length(wds.nodes.ID);
        num_of_vars2=length(wds.edges.ID);
        fprintf("\n\t Number of unknown without pivoting : %g",num_of_vars);
        fprintf("\n\t Number of unknown with    pivoting : %g, %g%%",num_of_vars2,num_of_vars2/num_of_vars*100);
    end
end
end

function obj = pivot_objective(pivot_edge_idx)
global wds
global edgepaths edgecycles N_nodes_r1 epanet_edge_idx
global DEBUG
out=0;
PENALTY=[];
% pivot_edges_idx is epanet indexing!
% edgepaths & cyclepaths are Matlab graph indexing -> use epanet_edge_idx() to get epanet indexing!
if DEBUG>1
    fprintf("\n pivot_edge_idx:\n");
    disp(pivot_edge_idx');
    wds.edges.ID{pivot_edge_idx}
end
% Check if all paths contain one pivot
Nr=length(edgepaths);
for i=1:Nr
    is_found=0;
    for j=1:length(pivot_edge_idx)
        if sum(pivot_edge_idx(j)==epanet_edge_idx(edgepaths{i}))==1
            if DEBUG>1
                fprintf('\n\t edge %d is in path edge %d',pivot_edge_idx(j),i);
            end
            out=out-wds.edges.diameter(pivot_edge_idx(j));
            is_found=1;
        end
    end
    % No pivot flow in this path
    if is_found==0
        if DEBUG>0
            fprintf('\n No pivot flow in path #%d: ',i);
            edgepaths{i}
        end
        PENALTY=[PENALTY,1];
    end
end

% Check if all cycles contain one pivot
Nc=length(edgecycles);
for i=1:Nc
    is_found=0;
    for j=1:length(pivot_edge_idx)
        %fprintf('\n===================================');
        %epanet_edge_idx
        %epanet_edge_idx(pivot_edge_idx(j))
        %fprintf('\n\t i=%d (edgecycle), edge: %d, ID: %s',i,pivot_edge_idx(j),wds.edges.ID{epanet_edge_idx(pivot_edge_idx(j))});
        %fprintf('\n Edgecycle:');
        %wds.edges.ID{epanet_edge_idx(edgecycles{i})}
        %fprintf('\n pivots:');
        %wds.edges.ID{epanet_edge_idx(pivot_edge_idx)}
        %pivot_edge_idx(j)==edgecycles{i}
        if sum(pivot_edge_idx(j)==epanet_edge_idx(edgecycles{i}))==1
            if DEBUG>1
                fprintf('\n\t edge %s is in cycle #%d:',wds.edges.ID{pivot_edge_idx(j)},i);
                wds.edges.ID{epanet_edge_idx(edgecycles{i})}
            end
            out=out-wds.edges.diameter(pivot_edge_idx(j));
            is_found=1;
        end
    end
    % No pivot flow in this cycle
    if is_found==0
        if DEBUG>0
            fprintf('\n No pivot flow in cycle #%d: ',i);
            wds.edges.ID{epanet_edge_idx(edgecycles{i})}
            wds.edges.ID{pivot_edge_idx}
        end
        PENALTY=[PENALTY, 1];
    end
end

% Next, check for multiply added elements
if DEBUG>0
    fprintf("\n\n Checking if all pivots are unique...");
end
if length(pivot_edge_idx)~=length(unique(pivot_edge_idx))
    PENALTY=[PENALTY, 10];
    if DEBUG>0
        fprintf("\t no:");
        disp(unique(pivot_edge_idx));
    end
else
    if DEBUG>0
        fprintf("\t yes.");
    end
end

% Finally, chack the rank of Rs (i.e. if there is a node at which all flows are chosen as pivot)
rank_Rs=length(wds.nodes.ID)-N_nodes_r1;
if DEBUG>0
    fprintf("\n\n Checking if rank(Rs)=%d ...",rank_Rs);
end
[Rp,Rs]=split_R(pivot_edge_idx);
if rank(Rs)<rank_Rs
    PENALTY=[PENALTY, 10];
    if DEBUG>0
        fprintf("\t no: rank(Rs)=%d",rank(Rs));
        PENALTY
    end
else
    if DEBUG>0
        fprintf("\t yes.");
    end
end

if sum(PENALTY)>0
    obj=sum(PENALTY);
else
    obj=out;
end
if DEBUG>0
    fprintf("\n\n Value of the objective function: %g\n",obj);
end
end

function mutationChildren = MyMutation(parents, options, nvars, FitnessFcn, state, thisScore, thisPopulation)
global edgepaths edgecycles epanet_edge_idx

for i=1:length(parents)
    Nr=length(edgepaths);
    for j=1:Nr
        if (rand(1,1)<0.1)
            tmp=edgepaths{j};
            new_idx=randi([1 length(tmp)]);
            mutationChildren(i,j)=epanet_edge_idx(tmp(new_idx));
        else
            mutationChildren(i,j)=thisPopulation(parents(i),j);
        end
    end

    Nc=length(edgecycles);
    for j=1:Nc
        if (rand(1,1)<0.1)
            tmp=edgecycles{j};
            new_idx=randi([1 length(tmp)]);
            mutationChildren(i,Nr+j)=epanet_edge_idx(tmp(new_idx));
        else
            mutationChildren(i,Nr+j)=thisPopulation(parents(i),Nr+j);
        end
    end
end
end
