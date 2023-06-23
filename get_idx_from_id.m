function out=get_idx_from_id(ID)
global wds

for i=1:length(wds.edges.ID)
    if strcmp(wds.edges.ID{i},ID)
        out=wds.edges.type_idx(i);
        break;
    end
end
end
