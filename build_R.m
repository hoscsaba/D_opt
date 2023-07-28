function build_R()
global wds
global R D
R=zeros(length(wds.nodes.ID),length(wds.edges.ID));
for i=1:length(wds.edges.ID)
    tmp=wds.edges.node_idx{i};
    id_head=tmp(1); id_tail=tmp(2);
    R(id_head,i)=-1;
    R(id_tail,i)=1;
end
% Remove endnodes continuity equations
R(find(wds.nodes.type~=0),:)=[];
% Load demands into D
D=wds.nodes.demand';
D(find(wds.nodes.type~=0),:)=[];
end
