function change_length(ID,new_val)
global wds

for i=1:length(wds.edges.ID)
    if strcmp(wds.edges.ID{i},ID)
        ti=wds.edges.type_idx(i);
        wds.edges.L(ti)=new_val;
        break
    end
end
end