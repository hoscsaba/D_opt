function [Q,p,dp]=hidr_solver(USE_PIVOTING,SHOW_RESULTS)
global wds
global R f

%% Build graph
wds.graph=digraph(wds.edges.node_from_ID,wds.edges.node_to_ID);
wds.graph.Nodes.Name=wds.nodes.ID';
wds.graph.Edges.Name=wds.edges.ID';
%% Plot graph
% plot(wds.graph,'EdgeLabel',wds.Edges.Name);

%% Incidence matrix
%% if s is the source node of edge j: I(s,j)=-1
%% if t is the target node of edge j: I(t,j)= 1
R=incidence(wds.graph);

if USE_PIVOTING==1
    DO_PLOT=1;
    [Np,piv_idx]=find_pivot_flows(wds,DO_PLOT);
end

g=9.81; rho=1000;

x=[ones(1,wds.N_j), ones(1,length(wds.edges.ID))];

x=fsolve(@RHS,x);

p=x(1:wds.N_j);
Q=x(wds.N_j+1:end);
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
        fprintf('\n\t\t %i, ID: %5s ->: p=%5.2f mwc',i,wds.nodes.ID{i},p(i));
    end
    fprintf('\n\t Edges:');
    for i=1:wds.N_e
        fprintf('\n\t\t %i, ID: %5s -> Q=%+5.2e m3/h, dp=%5.2f mwc',i,wds.edges.ID{i},Q(i),dp(i));
    end
end
end

function out = RHS(x)
global wds
global N_n N_e
global A lambda L D g h
global R f

p=x(1:wds.N_j); % p: mwc
Q=x(wds.N_j+1:end)'; % Q:m3/h

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
        out(i,1)=ph+hh-pt-ht-h_friction(L,D,C,v);
    else
        wds.edges.type(i)
        error('Unknown edge type!')
    end
end
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

function R=build_R()
global wds
R=zeros(length(wds.nodes.ID),length(wds.edges.ID));
for i=1:length(wds.edges.node_id)
    tmp=edges.node_id{i};
    id_head=tmp(1); id_tail=tmp(2);
    R(i,id_head)=-1;
    R(i,id_tail)=1;
end
end

function set_R(edges,f)
global PIVOT_FLOW_ID USE_PIVOTING SLAVE_FLOW_ID

R=build_R(edges,length(f),length(edges))
pause

R=R(2:end-1,:);

SLAVE_FLOW_ID=[];

if USE_PIVOTING==1
    Rp=[]; Rs=[]; fp=[];
    for i=1:N_e
        [val,idx]=max(i==PIVOT_FLOW_ID);
        if val==1
            Rp=[Rp,R(:,i)];
            fp=[fp;f(i)];
        else
            Rs=[Rs,R(:,i)];
            SLAVE_FLOW_ID=[SLAVE_FLOW_ID, i];
        end
    end
    Rpivot=-inv(Rs)*Rp;
    Dpivot=inv(Rs)*f;
end
end

function Q = reconstruct_Q_vec(Qp);
global N_e PIVOT_FLOW_ID SLAVE_FLOW_ID
Q=zeros(N_e,1);
for i=1:length(PIVOT_FLOW_ID)
    idx=PIVOT_FLOW_ID(i);
    Q(idx)=Qp(i);
end
Qs=Dpivot+Rpivot*Qp;
for i=1:length(SLAVE_FLOW_ID)
    idx=SLAVE_FLOW_ID(i);
    Q(idx)=Qs(i);
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
    out=4.727*C^(-1.852)*D^(-4.871)*L;
else
    error('Unknown Headloss formula!');
end
end
