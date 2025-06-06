function out=get_node_idx_from_id(ID)
global wds

for i=1:length(wds.nodes.ID)
    if strcmp(wds.nodes.ID{i},ID)
        out=i;
        break;
    end
end
end
