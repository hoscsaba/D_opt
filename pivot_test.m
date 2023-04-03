function pivot_test

    %% Pivot flow rate solver testing. Solve the same system first without, then with pivoting 

    clear all, close all, clc

    global wds USE_PIVOTING

    %fname="/Users/hoscsaba/Oktatas/Projektek/2022_23_2/medencek2.inp";
    fname='systems/epanet_tutorial2.inp';
    %fname='systems/pivot_sample.inp';
    %fname='systems/Net1.inp';
    %fname='systems/Anytown.inp';
    %fname='systems/d-town.inp';
    %fname='systems/MICROPOLIS_v1.inp';
    %fname='systems/PacificCity.inp';
    %fname='systems/Hanoi.inp';
    %% Load system
    DEBUG_LEVEL=3;
    wds=load_epanet(fname,DEBUG_LEVEL);

    SHOW_RESULTS=0;
    DO_PLOT=0;

    N=100;
    
    %% Solve system without pivoting
    USE_PIVOTING=0;
    t0=tic;
    for i=1:N, [Q1,p1,dp1]=hidr_solver(SHOW_RESULTS,DO_PLOT); end
    t1=toc(t0);

    %% Solve system with pivoting
    USE_PIVOTING=1;
    t0=tic;
    for i=1:N, [Q2,p2,dp2]=hidr_solver(SHOW_RESULTS,DO_PLOT); end
    t2=toc(t0);

    fprintf('\n\n Comparing results:');
    fprintf('\n\t |Q1-Q2|/|Q1|=%5.3e',norm(Q1-Q2)/norm(Q1));
    fprintf('\n\t |p1-p2|/|p1|=%5.3e',norm(p1-p2)/norm(p1));
    fprintf('\n Timing:\n\t t1=%5.3e s',t1);
    fprintf('\n\t t2=%5.3e s (%g %% of t1)\n\n',t2,t2/t1*100);

end

