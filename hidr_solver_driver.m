function hidr_solver_driver
    clear all, close all, clc

    global wds

    fname='systems/epanet_tutorial2.inp';
    %fname='systems/Net1.inp';
    %fname='systems/Anytown.inp';
    %fname='systems/d-town.inp';
    %fname='systems/MICROPOLIS_v1.inp';
    %fname='systems/PacificCity.inp';
    %fname='systems/Hanoi.inp';
    %% Load systems
    DEBUG_LEVEL=4;
    wds=load_epanet(fname,DEBUG_LEVEL);

    %% Solve system
    USE_PIVOTING=0;
    SHOW_RESULTS=1;
    [Q,p,dp]=hidr_solver(USE_PIVOTING,SHOW_RESULTS);

    return

    % Nodes
    N_n=7; % nodes
    N_r=2; % rank-1 (end) nodes
    nodes.h=zeros(1,N_n); nodes.h(end)=30;
    cons_base=1; % m3/h
    nodes.f=ones(N_n-N_r,1)*cons_base;

    [Q,p,dp]=hidr_solver(edges,nodes);

end

function out = Hpump(Q)
    a0=50; Q0=10; a2=a0/Q0^2;
    out=a0-a2*Q^2;
end
