function [Q,p,dp]=hydr_solver(varargin)
global wds USE_PIVOTING SHOW_RESULTS DEBUG_LEVEL
global xini

g=9.81;

switch nargin
    case 1
        xini=varargin{1};
    case 0
        switch USE_PIVOTING
            case 0
                build_R();
                xini=[ones(1,wds.N_j), ones(1,length(wds.edges.ID))];
            case 1
                %x=[ones(1,wds.N_j), ones(1,Np)];
                xini=ones(1,length(wds.edges.ID));
            otherwise
                USE_PIVOTING
                error('hydr_solver -> USE_PIVOTING must be 0 or 1!');
        end
    otherwise
        error('hydr_solver -> incorrect number of input arguments!');
end

%% Incidence matrix
%% if s is the source node of edge j: I(s,j)=-1
%% if t is the target node of edge j: I(t,j)= 1
%% WARNING: Matlab's built-in incidence matrix will give different node order!
%%build_R();

%% If pivoting is switched on, find pivot flow rates and build Rp and Rs
% if USE_PIVOTING==1
%     piv_idx=find_pivot_flows(DO_PLOT);
%     Np=length(piv_idx);
%     if SHOW_RESULTS==1
%         fprintf("\n\n These are the %d pivot flow rates:",length(piv_idx));
%         for i=1:Np
%             idx=wds.edges.type_idx(piv_idx(i));
%             fprintf("\n\t idx: %2d, ID: %s, D=%g, L=%g",piv_idx(i),wds.edges.ID{piv_idx(i)},...
%                 wds.edges.diameter(idx),wds.edges.pipe.L(idx));
%         end
%     end
%     [Rp,Rs]=split_R(piv_idx);
%     Rsinv_D=inv(Rs)*D;
%     Rsinv_Rp=inv(Rs)*Rp;
%     x=[ones(1,wds.N_j), ones(1,Np)];
% else
%     x=[ones(1,wds.N_j), ones(1,length(wds.edges.ID))];
% end

%% Solve system
%options = optimset('Display','iter','TolX',1e-4);
if DEBUG_LEVEL>3
options = optimoptions('fsolve',...
    'MaxFunctionEvaluations',1.42e4*10,...
    'TolX',1e-3,...
    'Display','iter',...
    'PlotFcn',@optimplotfirstorderopt);
else
    options= optimoptions('fsolve',...
        'MaxFunctionEvaluations',1.42e4*10,...
        'TolX',1e-3);
end

x=fsolve(@RHS,xini,options);
xini=x;

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
        fprintf('\n\t\t %i, ID: %5s, p=%+5.2f mwc',i,wds.nodes.ID{i},p(i));
    end
    fprintf('\n\t Edges:');
    for i=1:wds.N_e
        fprintf('\n\t\t %i, ID: %5s, Q=%+6.2f m3/h = %+6.2f lps, dp=%+5.2f mwc',...
            i,wds.edges.ID{i},Q(i),Q(i)*1000/3600,dp(i));
    end
end
end

function out = RHS(x)
global wds
global N_e
global A  L D g
global R
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
        L=wds.edges.length(i);
        D=wds.edges.diameter(i);
        A=D^2*pi/4;
        v=Q(i)/3600/A;
        C=wds.edges.pipe.roughness(idx);
        dh=h_friction(L,D,C,v);
        out(i,1)=ph+hh-pt-ht-abs(dh)*sign(v);
    elseif wds.edges.type(i)==1 % pump
        idx_p=wds.edges.type_idx(i);
        idx_c=wds.edges.pump.headcurve_idx(idx_p);
        Hpump=interp1(wds.curves.x{idx_c},wds.curves.y{idx_c},Q(i),'linear','extrap');
        out(i,1)=ph+hh-pt-ht+Hpump;
        %figure(1)
        %xx=wds.curves.x{idx_c};
        %yy=wds.curves.y{idx_c};
        %plot(xx,yy,'r-x',Q(i),Hpump,'ro');
        %drawnow
    elseif wds.edges.type(i)==2 % TCV valve
        %L=wds.edges.L(idx);
        D=wds.edges.diameter(i);
        v=Q(i)/3600/A;
        dh=0.01;
        out(i,1)=ph+hh-pt-ht-dh;
    elseif wds.edges.type(i)==3 % PRV valve
        %L=wds.edges.L(idx);
        D=wds.edges.diameter(i);
        v=Q(i)/3600/A;
        dh=0.01;
        out(i,1)=ph+hh-pt-ht-dh;
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



%function [Rp,Rs]=split_R(piv_idx)
%    global R D wds
%global Rsinv_D Rsinv_Rp
%    Rp=[]; Rs=[];
%R
%piv_idx
%wds.edges.ID{piv_idx}
%pause
%    for i=1:length(R(1,:))
%        if sum(piv_idx==i)>0
%            Rp=[Rp,R(:,i)];
%        else
%            Rs=[Rs,R(:,i)];
%        end
%    end
%    Rs
%    inv(Rs)
%    pause
%    Rsinv_D=inv(Rs)*D;
%    Rsinv_Rp=inv(Rs)*Rp;
%end

function Q = reconstruct_Q_vec(Qp)
global pivot_edge_idx Rsinv_D Rsinv_Rp

Qs=Rsinv_D-Rsinv_Rp*Qp';
Q=[];
idx=1; Qs_idx=1;
while idx<=length(Qs)+length(pivot_edge_idx)
    tmp=find(1==(idx==pivot_edge_idx));
    if ~isempty(tmp)
        Q(1,pivot_edge_idx(tmp))=Qp(tmp);
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
elseif strcmp(wds.options.Headloss,'C-M')
    % 1 m = 3.281 ft;
    D_feet = D*3.281;
    L_feet = L*3.281;
    A=4.66*C^(2)*D_feet^(-5.33)*L_feet;
    B=2;
    Q_cfs=(abs(v)*D^2*pi/4)*35.316;
    out=A*Q_cfs^B/3.281;
elseif strcmp(wds.options.Headloss,'D-W')
    % 1 m = 3.281 ft;
    % Re=(abs(v)*D)/10^(-6);
    % D_feet = D*3.281;
    Q_cfs=(abs(v)*D^2*pi/4)*35.316;
    Re=(4*abs(Q_cfs))/(pi*D*10^(-6)); % nem jó a Re, vagy nem tudom
    if Re<4000
        F=64/Re;
        D_feet = D*3.281;
        L_feet = L*3.281;
        A=0.0252*F*D_feet^(-5)*L_feet;
        B=2;
        Q_cfs=(abs(v)*D^2*pi/4)*35.316;
        out=A*Q_cfs^B/3.281;
    else
        D_feet = D*3.281;
        L_feet = L*3.281;
        F=0.25/(log10(C/(3.7*D_feet)+5.74/Re^(0.9)))^2;
        A=0.0252*F*D_feet^(-5)*L_feet;
        B=2;
        Q_cfs=(abs(v)*D^2*pi/4)*35.316;
        out=A*Q_cfs^B/3.281;
    end
else
    error('Unknown Headloss formula!');
end
if L<0.01
    out=0;
end

end
