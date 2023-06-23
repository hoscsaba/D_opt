function hydr_opti_L_driver_npipes
clear all, close all, clc

global wds DEBUG_LEVEL USE_PIVOTING SHOW_RESULTS
global idx_pipes id_pipes_to_optimize idx_pipes_to_optimize

probname='mot_example_L';
fname=fullfile('systems',[probname,'.inp']);

%% Load system to solver
DEBUG_LEVEL=0;
wds=load_epanet(fname,DEBUG_LEVEL);

%% set up problem
USE_PIVOTING=0; SHOW_RESULTS=0;
id_pipes_to_optimize={"l2d1","l2d2","l2d3","l2d4","l2d5","l2d6","l2d7",...
    "l2d8","l2d9","l2d10","l2d11","l2d12","l2d13","l2d14"};
for i=1:length(id_pipes_to_optimize)
    idx_pipes_to_optimize(i)=get_idx_from_id(id_pipes_to_optimize{i});
end
idx_pipes=[1,3:72];
Lmin=0.01; %m
Lmax=14000;

%% Optimize with fmincon
% constraint: Ax<b
% x>Dmin
Acon=-eye(length(id_pipes_to_optimize));
bcon=-Lmin*ones(1,length(id_pipes_to_optimize));
Aeq=ones(1,length(id_pipes_to_optimize));
beq=Lmax;
tic
[Lopt1,costval1]=fmincon(@cost,Lmin*10*ones(1,length(id_pipes_to_optimize)),...
    Acon,bcon,Aeq,beq);
t1=toc;
 
% optimize with ga
lb = Lmin*ones(1,length(id_pipes_to_optimize)); 
ub = Lmax*ones(1,length(id_pipes_to_optimize)); 
nonlcon = [];
opts = optimoptions(@ga,'PlotFcn',{@gaplotbestf,@gaplotstopping});
tic
[Lopt2,costval2] = ga(@cost,length(id_pipes_to_optimize),...
    Acon,bcon,Aeq,beq,lb,ub,nonlcon,[],opts);
t2=toc;

%% Results
fp=fopen('hydr_opti_driver_L_npipes.res','w');
fprintf(fp,'\n fmincon: fmin=%g, time: %g s',costval1,t1);
fprintf(fp,'\n ga     : fmin=%g, time: %g s\n',costval2,t2);
fprintf(fp,'\n name  fmincon  ga (m)');
for i=1:length(Dopt1)
    fprintf(fp,'\n %s: %5.3e %5.3e',id_pipes_to_optimize{i},Lopt1(i),Lopt2(i));
end
fclose(fp);

end
