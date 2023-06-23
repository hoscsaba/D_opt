function x=hydr_solver_initiate(USE_PIVOTING, SHOW_RESULTS,DO_PLOT)
	global wds 
	global R D
	global piv_idx Rsinv_D Rsinv_Rp Np epanet_edge_idx

	%% Build graph
	edgeNames=wds.edges.ID';
	wds.graph=graph(wds.edges.node_from_ID,wds.edges.node_to_ID,table(edgeNames),wds.nodes.ID');
	%% Warning: Matlab's constructor reorders edges! We build a vocabulary between the two edges lists.
	%% graph_edge_idx(i)=j -> the ith edge in wds.graph is the jth edge in Epanet input list
	if USE_PIVOTING==0
		for graph_edge_idx=1:wds.N_e
			name = wds.graph.Edges.edgeNames{graph_edge_idx};
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
	else
		if DO_PLOT==1
			plot(wds.graph,'EdgeLabel',wds.graph.Edges.edgeNames);
		end
	end

	%% Incidence matrix
	%% if s is the source node of edge j: I(s,j)=-1
	%% if t is the target node of edge j: I(t,j)= 1
	%% WARNING: Matlab's built-in incidence matrix will give different node order!
	build_R();

	%% If pivoting is switched on, find pivot flow rates and build Rp and Rs
	if USE_PIVOTING==1
		piv_idx=find_pivot_flows(DO_PLOT,1);
		Np=length(piv_idx);
% 		if DEBUG_LEVEL>2
% 			fprintf("\n\n These are the %d pivot flow rates:",length(piv_idx));
% 			for i=1:Np
% 				idx=wds.edges.type_idx(piv_idx(i));
% 				fprintf("\n\t idx: %2d, ID: %s, D=%g, L=%g",piv_idx(i),wds.edges.ID{piv_idx(i)},...
% 					wds.edges.diameter(piv_idx(i)),wds.edges.length(piv_idx(i)));
% 			end
% 		end
		[Rp,Rs]=split_R(piv_idx);    
		Rsinv_D=inv(Rs)*D;
		Rsinv_Rp=inv(Rs)*Rp;
		x=[ones(1,wds.N_j), ones(1,Np)];
	else
		x=[ones(1,wds.N_j), ones(1,length(wds.edges.ID))];
	end


end

function build_R()
	global wds
	global R D
	R=zeros(length(wds.nodes.ID),length(wds.edges.ID));
	for i=1:length(wds.edges.ID)
		tmp=wds.edges.node_idx{i};
		id_head=tmp(1); id_tail=tmp(2);
		R(id_head,i)=-1;
		R(id_tail,i)=1;
	end
	%% Remove endnodes continuity equations
	R(find(wds.nodes.type~=0),:)=[];
	%% Load demands into D
	D=wds.nodes.demand';
	D(find(wds.nodes.type~=0),:)=[];
end


