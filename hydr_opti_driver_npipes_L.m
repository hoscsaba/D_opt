function hydr_opti_driver_npipes_L
clear all, close all, clc

global wds DEBUG_LEVEL USE_PIVOTING SHOW_RESULTS OPT_PAR USER_GRADIENT
global idx_pipes id_pipes_to_optimize idx_pipes_to_optimize xini
global probname
global costval1 t1 out1
global costval2 t2 out2
global costval3 t3 out3
global fname_prefix

probname='mot_example_L_no_pump2';
fname=fullfile('systems',[probname,'.inp']);

%% Load system to solver
DEBUG_LEVEL=0;
wds=load_epanet(fname);

%% set up problem
USE_PIVOTING=0; 
SHOW_RESULTS=0;
OPT_PAR       = 'L';

id_pipes_to_optimize={
    "l2d1","l2d2","l2d3","l2d4","l2d5","l2d6","l2d7","l2d8","l2d9","l2d10","l2d11","l2d12","l2d13","l2d14",...
    "l3d1","l3d2","l3d3","l3d4","l3d5","l3d6","l3d7","l3d8","l3d9","l3d10","l3d11","l3d12","l3d13","l3d14",...
    "l6d1","l6d2","l6d3","l6d4","l6d5","l6d6","l6d7","l6d8","l6d9","l6d10","l6d11","l6d12","l6d13","l6d14",...
    "l7d1","l7d2","l7d3","l7d4","l7d5","l7d6","l7d7","l7d8","l7d9","l7d10","l7d11","l7d12","l7d13","l7d14",...
    "l8d1","l8d2","l8d3","l8d4","l8d5","l8d6","l8d7","l8d8","l8d9","l8d10","l8d11","l8d12","l8d13","l8d14"};
for i=1:length(id_pipes_to_optimize)
    idx_pipes_to_optimize(i)=get_idx_from_id(id_pipes_to_optimize{i});
end
idx_pipes=1:1:length(wds.edges.ID);
Lmin=0.01;
Lmax=14000;

xini=hydr_solver_initiate();

ps=length(id_pipes_to_optimize); % problem size
x0=10*ones(1,ps);
Nseg=14;
Aeq=[ones(1,Nseg),zeros(1,Nseg),zeros(1,Nseg),zeros(1,Nseg),zeros(1,Nseg);
    zeros(1,Nseg), ones(1,Nseg),zeros(1,Nseg),zeros(1,Nseg),zeros(1,Nseg);
    zeros(1,Nseg),zeros(1,Nseg), ones(1,Nseg),zeros(1,Nseg),zeros(1,Nseg);
    zeros(1,Nseg),zeros(1,Nseg),zeros(1,Nseg), ones(1,Nseg),zeros(1,Nseg);
    zeros(1,Nseg),zeros(1,Nseg),zeros(1,Nseg),zeros(1,Nseg), ones(1,Nseg)]; 

beq=Lmax*ones(5,1);
lb=Lmin*ones(1,ps);
ub=Lmax*ones(1,ps);

%% Optimize with fmincon, without gradient information
USER_GRADIENT = 0; % 1: yes, 0: no
if USER_GRADIENT==1
    options = optimoptions(@fmincon,...
        'PlotFcn',{@optimplotx,@optimplotfval,@optimplotfirstorderopt},...
        'SpecifyObjectiveGradient',true);
else
     options = optimoptions(@fmincon,...
        'PlotFcn',{@optimplotx,@optimplotfval,@optimplotfirstorderopt});
end
tic
[Lopt1,costval1,exitflag,out1]=fmincon(@cost,x0,[],[],Aeq,beq,lb,ub,[],options);
t1=toc;
save('out1.mat','out1')
 
%% Optimize with fmincon, using gradient information
USER_GRADIENT = 1; % 1: yes, 0: no
if USER_GRADIENT==1
    options = optimoptions(@fmincon,...
        'PlotFcn',{@optimplotx,@optimplotfval,@optimplotfirstorderopt},...
        'SpecifyObjectiveGradient',true);
else
     options = optimoptions(@fmincon,...
        'PlotFcn',{@optimplotx,@optimplotfval,@optimplotfirstorderopt});
end
tic
[Lopt2,costval2,exitflag,out2]=fmincon(@cost,x0,[],[],Aeq,beq,lb,ub,[],options);
t2=toc;
save('out2.mat','out2')

% optimize with ga
nonlcon = [];
opts = optimoptions(@ga,'PlotFcn',{@gaplotbestf,@gaplotstopping});
tic
[Lopt3,costval3,exitflag,out3] = ga(@cost,ps,[],[],Aeq,beq,lb,ub,nonlcon,[],opts);
t3=toc;
save('out3.mat','out3')

%% Results
fname_prefix='mot_example_L_no_pump_';
write_solutions_to_out_file([fname_prefix,'npipes.res'],Lopt1,Lopt2,Lopt3);

end

function run_optimizer()
global USER_GRADIENT OPT_SOLVER
switch OPT_SOLVER
    case 'fmincon'
if USER_GRADIENT==1
    options = optimoptions(@fmincon,...
        'PlotFcn',{@optimplotx,@optimplotfval,@optimplotfirstorderopt},...
        'SpecifyObjectiveGradient',true);
else
     options = optimoptions(@fmincon,...
        'PlotFcn',{@optimplotx,@optimplotfval,@optimplotfirstorderopt});
end
tic
[Lopt1,costval1,exitflag,out1]=fmincon(@cost,x0,[],[],Aeq,beq,lb,ub,[],options);
t1=toc;
    case 'ga'
        nonlcon = [];
opts = optimoptions(@ga,'PlotFcn',{@gaplotbestf,@gaplotstopping});
tic
[Lopt3,costval3,exitflag,out3] = ga(@cost,ps,[],[],Aeq,beq,lb,ub,nonlcon,[],opts);
t3=toc;

save('out1.mat','out1')
end