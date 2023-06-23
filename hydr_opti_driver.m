function hydr_opti_driver
clear all, close all, clc

global wds

fname='systems/mot_example.inp';

%% Load system
DEBUG_LEVEL=0;
wds=load_epanet(fname,DEBUG_LEVEL);

%% Solve system
USE_PIVOTING=0; SHOW_RESULTS=0;
junctions_to_optimize=["1","2"];
idx_pipes=[1:3,5:8];

Dvec1=linspace(10,200,5);
Dvec2=linspace(10,300,5);
for i=1:length(Dvec1)
    change_diameter(junctions_to_optimize{1},Dvec1(i));
    for j=1:length(Dvec2)
     change_diameter(junctions_to_optimize{2},Dvec2(j));
    [Q,p,dp]=hydr_solver(USE_PIVOTING,SHOW_RESULTS);
    Q(idx_pipes)
    dp(idx_pipes)
    pause
    Ploss(i,j)=dot(Q(idx_pipes),dp(idx_pipes));
    fprintf('\n D%s=%5.0f, D%s=%5.0f, Cost=%5.3e',...
        junctions_to_optimize{1},Dvec1(i), ...
        junctions_to_optimize{2},Dvec2(j),Ploss(i,j));
    end
end
[x,y]=meshgrid(Dvec1,Dvec2);
contour(x,y,Ploss);

end

function change_diameter(ID,new_val)
global wds

for i=1:length(wds.edges.ID)
    %fprintf("\n i:%2d, ID: %s",i,wds.edges.ID{i});
    if strcmp(wds.edges.ID{i},ID)
        ti=wds.edges.type_idx(i);
        %D=wds.edges.pipe.diameter(ti);
        %fprintf(" -> D=%g",D);
        wds.edges.diameter(ti)=new_val;
    end
end

end

function out=get_diameter(ID)
global wds

for i=1:length(wds.edges.ID)
    if strcmp(wds.edges.ID{i},ID)
        ti=wds.edges.type_idx(i);
        out=wds.edges.diameter(ti);
        break;
    end
end

end

function list_diameters()
global wds
for i=1:length(wds.edges.ID)
    fprintf("\n i:%2d, ID: %s -> D=%g",i,wds.edges.ID{i},...
        get_diameter(wds.edges.ID{i}));
    
end
end