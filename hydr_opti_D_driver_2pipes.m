function hydr_opti_D_driver_2pipes
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
id_pipes_to_optimize={"p2","p6"};
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
fp=fopen('hydr_opti_driver_2pipes.res','w');
fprintf(fp,'\n fmincon: fmin=%g, time: %g s',costval1,t1);
fprintf(fp,'\n ga     : fmin=%g, time: %g s\n',costval2,t2);
fprintf(fp,'\n name  fmincon  ga (mm)');
for i=1:length(Dopt1)
    fprintf(fp,'\n %s: %5.3e %5.3e',id_pipes_to_optimize{i},Dopt1(i)*1000,Dopt2(i)*1000);
end
fclose(fp);

%% Plot
% compute_surface=0;
% if compute_surface==0
%     load(['hydr_opti_2pipes_data_',probname,'.mat']);
% else
%     Dvec1=linspace(Dmin,0.2,20);
%     Dvec2=linspace(Dmin,0.2,100);
%     for i=1:length(Dvec1)
%         change_diameter(id_pipes_to_optimize{1},Dvec1(i));
%         for j=1:length(Dvec2)
%             change_diameter(id_pipes_to_optimize{2},Dvec2(j));
%             Ploss(j,i)=cost([Dvec1(i),Dvec2(j)]);
%             fprintf('\n D%s=%5.0f mm, D%s=%5.0f mm, Cost=%5.3e',...
%                 id_pipes_to_optimize{1},Dvec1(i)*1000, ...
%                 id_pipes_to_optimize{2},Dvec2(j)*1000,Ploss(j,i));
%         end
%     end
%     save(['hydr_opti_2pipes_data_',probname,'.mat']);
%     hold off
% end
% 
% figure(2)
% [x,y]=meshgrid(Dvec1,Dvec2);
% contour(x,y,log(Ploss),500), hold on
% plot(Dopt1(1),Dopt2(2),'r*'), hold on
% plot(Dopt1(1),Dopt2(2),'bo'), hold off

% Output:
% fmincon: fmin=483216, time: 6.51091 s
%     0.0100    0.0718
%  ga     : fmin=482774, time: 499.275 s
%     0.0090    0.0696


end
