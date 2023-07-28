function change_length(ID,new_val)
global wds

for i=1:length(wds.edges.ID)
    if strcmp(wds.edges.ID{i},ID)
        wds.edges.length(i)=new_val;
	break
    end
end
end
