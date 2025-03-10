function hydr_opti_D_driver_npipes
clear all, close all, clc

global wds DEBUG_LEVEL USE_PIVOTING SHOW_RESULTS
global idx_pipes id_pipes_to_optimize

probname='mot_example';
fname=fullfile('systems',[probname,'.inp']);

%% Load system to solver
DEBUG_LEVEL=0;
wds=load_epanet(fname,DEBUG_LEVEL);
change_diameter("p5",0.001);

%% set up problem
USE_PIVOTING=0; SHOW_RESULTS=0;
id_pipes_to_optimize={"p1","p2","p3","p6","p7","p8"};
idx_pipes=[1:3,5:8];
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
fp=fopen('hydr_opti_driver_npipes.res','w');
fprintf(fp,'\n fmincon: fmin=%g, time: %g s',costval1,t1);
fprintf(fp,'\n ga     : fmin=%g, time: %g s\n',costval2,t2);
fprintf(fp,'\n name  fmincon  ga (mm)');
for i=1:length(Dopt1)
    fprintf(fp,'\n %s: %5.3e %5.3e',id_pipes_to_optimize{i},Dopt1(i)*1000,Dopt2(i)*1000);
end
fclose(fp);

end