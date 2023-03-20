function hidr_opti_driver
clear all, close all, clc

global wds

fname='systems/epanet_tutorial2.inp';

%% Load system
DEBUG_LEVEL=0;
wds=load_epanet(fname,DEBUG_LEVEL);

%% Solve system
USE_PIVOTING=0;
SHOW_RESULTS=0;
[Q,p,dp]=hidr_solver(USE_PIVOTING,SHOW_RESULTS);

%P=sum(Q.*dp);
list_diameters();

change_diameter("7",42);

list_diameters();



end

function change_diameter(ID,new_val)
global wds

for i=1:length(wds.edges.ID)
    %fprintf("\n i:%2d, ID: %s",i,wds.edges.ID{i});
    if strcmp(wds.edges.ID{i},ID)
        ti=wds.edges.type_idx(i);
        %D=wds.edges.pipe.diameter(ti);
        %fprintf(" -> D=%g",D);
        wds.edges.pipe.diameter(ti)=new_val;
    end
end

end

function out=get_diameter(ID)
global wds

for i=1:length(wds.edges.ID)
    if strcmp(wds.edges.ID{i},ID)
        ti=wds.edges.type_idx(i);
        out=wds.edges.pipe.diameter(ti);
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