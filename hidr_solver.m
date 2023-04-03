function [Q,p,dp]=hidr_solver(SHOW_RESULTS,DO_PLOT)
    global wds USE_PIVOTING
    global R D 
    global piv_idx Rsinv_D Rsinv_Rp Np

    g=9.81; rho=1000;

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
        piv_idx=find_pivot_flows(DO_PLOT);
        Np=length(piv_idx);
        if SHOW_RESULTS==1
            fprintf("\n\n These are the %d pivot flow rates:",length(piv_idx));
            for i=1:Np
                idx=wds.edges.type_idx(piv_idx(i));
                fprintf("\n\t idx: %2d, ID: %s, D=%g, L=%g",piv_idx(i),wds.edges.ID{piv_idx(i)},...
                    wds.edges.pipe.diameter(idx),wds.edges.pipe.L(idx));
            end
        end
        split_R(piv_idx);
        x=[ones(1,wds.N_j), ones(1,Np)];
    else
        x=[ones(1,wds.N_j), ones(1,length(wds.edges.ID))];
    end

    %% Solve system
    x=fsolve(@RHS,x);

    %% Recover pressures and flow rates
    p=x(1:wds.N_j);
    if USE_PIVOTING==1
        Q=reconstruct_Q_vec(x(wds.N_j+1:end));
    else
        Q=x(wds.N_j+1:end);
    end

    % Compute pressure drop
    for i=1:wds.N_e
        tmp=wds.edges.node_idx{i};
        head=tmp(1); tail=tmp(2);
        hh=get_h_p(head);
        ht=get_h_p(tail);
        if wds.nodes.type(head)==0 % junction, pressure is unknown
            ph=p(wds.nodes.type_idx(head));
        else % tank or reservoir, pressure known
            ph=0;
        end
        if wds.nodes.type(tail)==0 % junction, pressure is unknown
            pt=p(wds.nodes.type_idx(tail));
        else % tank or reservoir, pressure is known
            pt=0;
        end

        dp(i)=hh+ph-(ht+pt);
    end

    if SHOW_RESULTS==1
        fprintf('\nResults:');
        fprintf('\n\t Nodes:');
        for i=1:wds.N_j
            fprintf('\n\t\t %i, ID: %5s, p=%5.2f mwc',i,wds.nodes.ID{i},p(i));
        end
        fprintf('\n\t Edges:');
        for i=1:wds.N_e
            fprintf('\n\t\t %i, ID: %5s, Q=%+5.2e m3/h, dp=%5.2f mwc',i,wds.edges.ID{i},Q(i),dp(i));
        end
    end
end

function out = RHS(x)
    global wds
    global N_n N_e
    global A lambda L D g h
    global R f
    global USE_PIVOTING Np

    p=x(1:wds.N_j); % p: mwc
    if USE_PIVOTING==1
        Qp=x(wds.N_j+1:wds.N_j+Np);
        Q=reconstruct_Q_vec(Qp);
    else
        Q=x(wds.N_j+1:end); % Q:m3/h
    end
    %% 1...N_e: edge equations
    N_e=length(wds.edges.ID);
    for i=1:N_e
        tmp=wds.edges.node_idx{i};
        head=tmp(1); tail=tmp(2);
        hh=get_h_p(head); % geodetic height, node property
        ht=get_h_p(tail); % geodetic height, node property
        if wds.nodes.type(head)==0 % junction, pressure is unknown
            ph=p(wds.nodes.type_idx(head));
        else % tank or reservoir, pressure known
            ph=0; % TODO import the pressure set in Epanet
        end
        if wds.nodes.type(tail)==0 % junction, pressure is unknown
            pt=p(wds.nodes.type_idx(tail));
        else % tank or reservoir, pressure is known
            pt=0;
        end

        %fprintf("\n edge: %d, head_node: %g (ph=%5.2fm, hh=%5.2fm), tail_node: %g, (pt=%5.2fm, ht=%5.2fm), v=%5.3f m/s",i,head,ph,hh,tail,pt,ht,v);
        if wds.edges.type(i)==0 % pipe
            idx=wds.edges.type_idx(i);
            L=wds.edges.pipe.L(idx);
            D=wds.edges.pipe.diameter(idx);
            A=D^2*pi/4;
            v=Q(i)/3600/A;
            C=wds.edges.pipe.roughness(idx); 
            dh=h_friction(L,D,C,v);
            out(i,1)=ph+hh-pt-ht-abs(dh)*sign(v);
        else
            wds.edges.type(i)
            error('Unknown edge type!')
        end
    end

    if USE_PIVOTING==0
        % Continuity equations
        % nodes of tanks (wds.nodes.type=1) and
        % reservoirs (wds.nodes.type=2) are skipped
        node_count=1;
        for i=1:length(wds.nodes.ID)
            if wds.nodes.type(i)==0
                out(N_e+node_count)=dot(R(i,:),Q)-wds.nodes.demand(i);
                node_count=node_count+1;
            end
        end
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

function split_R(piv_idx)
    global R D 
    global Rsinv_D Rsinv_Rp
    Rp=[]; Rs=[];
    for i=1:length(R(1,:))
        if sum(piv_idx==i)>0 
            Rp=[Rp,R(:,i)];
        else
            Rs=[Rs,R(:,i)];
        end
    end
    Rsinv_D=inv(Rs)*D;
    Rsinv_Rp=inv(Rs)*Rp;
end

function Q = reconstruct_Q_vec(Qp);
    global piv_idx Rsinv_D Rsinv_Rp
    Qs=Rsinv_D-Rsinv_Rp*Qp';
    Q=[];
    idx=1; Qs_idx=1;
    while idx<=length(Qs)+length(piv_idx)
        tmp=find(1==(idx==piv_idx));
        if ~isempty(tmp)
            Q(1,piv_idx(tmp))=Qp(tmp);
        else
            Q(1,idx)=Qs(Qs_idx);
            Qs_idx=Qs_idx+1;
        end
        idx=idx+1;
    end
end
function h=get_h_p(idx)
    global wds
    if wds.nodes.type(idx)==0 % junction
        nj=wds.nodes.type_idx(idx);
        h=wds.nodes.junction.elevation(nj);
    elseif wds.nodes.type(idx)==1 % tank
        nt=wds.nodes.type_idx(idx);
        h=wds.nodes.tank.elev(nt);
        h=h+wds.nodes.tank.Hini(nt);
    elseif wds.nodes.type(idx)==2 % reservoir
        nr=wds.nodes.type_idx(idx);
        h=wds.nodes.reservoir.H(nr);
    else
        error('Unknown node type!!!');
    end
end


function out=h_friction(L,D,C,v)
    global wds
    if strcmp(wds.options.Headloss,'H-W')
        % 1 m = 3.281 ft;
        D_feet = D*3.281;
        L_feet = L*3.281;
        A=4.727*C^(-1.852)*D_feet^(-4.871)*L_feet;
        B=1.852;
        Q_cfs=(abs(v)*D^2*pi/4)*35.316;
        out=A*Q_cfs^B/3.281;
    else
        error('Unknown Headloss formula!');
    end
end
