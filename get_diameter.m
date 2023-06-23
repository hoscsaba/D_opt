
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
