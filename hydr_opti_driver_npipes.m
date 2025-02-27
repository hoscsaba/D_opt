function hydr_opti_driver_npipes
close all, clc

global wds DEBUG_LEVEL USE_PIVOTING SHOW_RESULTS OPT_PAR USER_GRADIENT
global idx_pipes id_pipes_to_optimize idx_pipes_to_optimize
global probname
global costval1 t1 out1
global costval2 t2 out2
global costval3 t3 out3
global fname_prefix

probname='mot_example_no_pump';
fname=fullfile('systems',[probname,'.inp']);

%% Load system to solver
DEBUG_LEVEL=0;
wds=load_epanet(fname);

%% set up problem
USE_PIVOTING  = 0;
SHOW_RESULTS  = 0;
OPT_PAR       = 'D';
USER_GRADIENT = 0;
id_pipes_to_optimize={"p1","p2","p3","p6","p7","p8"};
for i=1:length(id_pipes_to_optimize)
    idx_pipes_to_optimize(i)=get_idx_from_id(id_pipes_to_optimize{i});
end
idx_pipes=1:1:length(wds.edges.ID);
Dmin=10/1000; %m

%% Optimize with fmincon, without gradient information
ps=length(id_pipes_to_optimize); % problem size
x0=10*Dmin*ones(1,ps);
%Acon=-eye(ps);
lb=Dmin*ones(1,ps);
USER_GRADIENT = 0; % 1: yes, 0: no
if USER_GRADIENT==1
    options = optimoptions(@fmincon,'SpecifyObjectiveGradient',true);
else
    options=[];
end
tic
[Dopt1,costval1,exitflag,out1]=fmincon(@cost,x0,[],[],[],[],lb,[],[],options);
t1=toc;

%% Optimize with fmincon, using gradient information
USER_GRADIENT = 1; % 1: yes, 0: no
if USER_GRADIENT==1
    options = optimoptions(@fmincon,'SpecifyObjectiveGradient',true);
else
    options=[];
end
tic
[Dopt2,costval2,exitflag,out2]=fmincon(@cost,x0,[],[],[],[],lb,[],[],options);
t2=toc;

%% Optimize with ga, using gradient information
% optimize with ga
opts = optimoptions(@ga,'PlotFcn',{@gaplotbestf,@gaplotstopping});
tic
[Dopt3,costval3,exitflag,out3] = ga(@cost,ps,[],[],[],[],lb,[],[],opts);
t3=toc;

%% Results
write_solutions_to_out_file([fname_prefix,'npipes.res'],Dopt1,Dopt2,Dopt3);
end
