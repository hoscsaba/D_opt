function hydr_opti_L_driver_npipes_L
clear all, close all, clc

global wds DEBUG_LEVEL USE_PIVOTING SHOW_RESULTS OPT_PAR USER_GRADIENT
global idx_pipes id_pipes_to_optimize idx_pipes_to_optimize xini
global probname
global costval1 t1 out1
global costval2 t2 out2
global costval3 t3 out3
global fname_prefix

probname='mot_example_L_no_pump';
fname=fullfile('systems',[probname,'.inp']);

%% Load system to solver
DEBUG_LEVEL=0;
wds=load_epanet(fname);

%% set up problem
USE_PIVOTING=0; 
SHOW_RESULTS=0;
OPT_PAR       = 'D';
USER_GRADIENT = 0;

id_pipes_to_optimize={"l2d1","l2d2","l2d3","l2d4","l2d5","l2d6","l2d7",...
    "l2d8","l2d9","l2d10","l2d11","l2d12","l2d13","l2d14"};
for i=1:length(id_pipes_to_optimize)
    idx_pipes_to_optimize(i)=get_idx_from_id(id_pipes_to_optimize{i});
end
idx_pipes=1:1:length(wds.edges.ID);
Lmin=0.01; %m
Lmax=14000;

xini=hydr_solver_initiate();

%% Optimize with fmincon, without gradient information
ps=length(id_pipes_to_optimize); % problem size
x0=Lmax/ps*ones(1,ps);
Aeq=ones(1,ps); beq=Lmax;
lb=Lmin*ones(1,ps);
ub=Lmax*ones(1,ps);

USER_GRADIENT = 0; % 1: yes, 0: no
if USER_GRADIENT==1
    options = optimoptions(@fmincon,'SpecifyObjectiveGradient',true);
else
    options=[];
end
tic
[Lopt1,costval1,exitflag,out1]=fmincon(@cost,x0,[],[],Aeq,beq,lb,ub,options);
t1=toc;
save('out1.mat','out1')
 
%% Optimize with fmincon, using gradient information
USER_GRADIENT = 1; % 1: yes, 0: no
if USER_GRADIENT==1
    options = optimoptions(@fmincon,'SpecifyObjectiveGradient',true);
else
    options=[];
end
tic
[Lopt2,costval2,exitflag,out2]=fmincon(@cost,x0,[],[],Aeq,beq,lb,[],[],options);
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
write_solutions_to_out_file([fname_prefix,'npipes.res'],Dopt1,Dopt2,Dopt3);

end
