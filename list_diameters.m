
function list_diameters()
global wds
for i=1:length(wds.edges.ID)
    fprintf("\n i:%2d, ID: %s -> D=%g",i,wds.edges.ID{i},...
        get_diameter(wds.edges.ID{i}));

end
end