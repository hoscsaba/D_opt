function hydr_opti_D_driver_1pipe
clear all, close all, clc

global wds DEBUG_LEVEL USE_PIVOTING SHOW_RESULTS
global pivot_edge_idx
global idx_pipes id_pipes_to_optimize idx_pipes_to_optimize

%% Some settings
DEBUG_LEVEL  = 0;
USE_PIVOTING = 1; 
PIVOT_METHOD = 1; % 0 - heuristic, 1 - spanning tree
DO_PLOT      = 0;
SHOW_RESULTS = 0;
probname='mot_example';
fname=fullfile('systems',[probname,'.inp']);

id_pipes_to_optimize={"p1"};

%% Load system to solver
wds=load_epanet(fname);

%% set up problem
if USE_PIVOTING==1
    pivot_edge_idx=find_pivot_flows(DO_PLOT,PIVOT_METHOD);
end

for i=1:length(id_pipes_to_optimize)
    idx_pipes_to_optimize(i)=get_idx_from_id(id_pipes_to_optimize{i});
end
idx_pipes=length(wds.edges.ID);
Dmin=10/1000; %m

%% Optimize with fmincon
% constraint: Ax<b
% x>Dmin
Acon=-eye(length(id_pipes_to_optimize));
bcon=-Dmin*ones(1,length(id_pipes_to_optimize));
tic
[Dopt1,costval1]=fmincon(@cost,Dmin*10*ones(1,length(id_pipes_to_optimize)),Acon,bcon);
t1=toc;

% optimize with ga
Aeq = []; beq = []; lb = []; ub = []; nonlcon = [];
opts = optimoptions(@ga,'PlotFcn',{@gaplotbestf,@gaplotstopping});
tic
[Dopt2,costval2] = ga(@cost,length(id_pipes_to_optimize),...
    Acon,bcon,Aeq,beq,lb,ub,nonlcon,[],opts);
t2=toc;

%% Results
fp=fopen('hydr_opti_D_driver_1pipe.res','w');
fprintf(fp,'\n USE_PIVOTING         : %g',USE_PIVOTING);
fprintf(fp,'\n USE_ANALYTIC_GRADIENT: %g',USE_PIVOTING);
fprintf(fp,'\n fmincon: fmin=%g, time: %g s',costval1,t1);
fprintf(fp,'\n ga     : fmin=%g, time: %g s\n',costval2,t2);
fprintf(fp,'\n name  fmincon  ga (mm)');
for i=1:length(Dopt1)
    fprintf(fp,'\n %s: %5.3e %5.3e',id_pipes_to_optimize{i},Dopt1(i)*1000,Dopt2(i)*1000);
end
fclose(fp);

Dvec1=linspace(Dmin,0.5);
for i=1:length(Dvec1)
    Ploss(i)=cost(Dvec1(i));
    fprintf('\n D%s=%5.0f, Cost=%5.3e',...
        id_pipes_to_optimize{1},Dvec1(i)*1000,Ploss(i));
end

figure(3)
plot(Dvec1,Ploss), hold on
plot(Dopt1,cost(Dopt1),'r*',Dopt2,cost(Dopt2),'bo')
hold off


end
