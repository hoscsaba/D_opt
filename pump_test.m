function pump_test
clear all, close all, clc

global wds USE_PIVOTING  L D n A

fname="systems/pump_test.inp";

DEBUG_LEVEL=5;
SHOW_RESULTS=1;
DO_PLOT=1;
USE_PIVOTING=0;

wds=load_epanet(fname,DEBUG_LEVEL);

[Q1,p1,dp1]=hidr_solver(SHOW_RESULTS,DO_PLOT);



% global Acsj Hmax Qmax n
% wds.options.Headloss
% D=0.05;
% A=D^2*pi/4;
% L=100;
%
% H=45; % m
% Q=20; % l/s
% Hmax=1.33*H;
% Qmax=2*Q;
%
%
%
% qvec=linspace(0,Qmax);
% hsz_vec=Hmax-Hmax/Qmax^2*qvec.^2;
% n=0.5/1000*3.281;
% for i=1:length(qvec)
%     v=qvec(i)/A/1000;
%     hcs_vec1(i)=h_friction(L,D,n,v);
% end
%
% Qmp=fsolve(@funtosolve,Q);
% Hmp=Hmax-Hmax/Qmax^2*Qmp^2;
%
% figure(1)
% plot(qvec,hsz_vec,'r',qvec,hcs_vec1,'g',Qmp,Hmp,'ko')
% title(['Munkapont adatai: Q=',num2str(Qmp),'l/s',', H=',num2str(Hmp),'m'])
% xlabel('Q, l/s')
% ylabel('H, m'), ylim([0 100])
% end
%
%
% function y=funtosolve(x)
% global Hmax Qmax L D n A
% Hsz=Hmax-Hmax/Qmax^2*x^2;
% v=x/A/1000;
% Hcs=h_friction(L,D,n,v);
% y=Hcs-Hsz;
% end
%
