function plot_wds()
global wds

edgeNames=wds.edges.ID';
G=digraph(wds.edges.node_from_ID,wds.edges.node_to_ID,table(edgeNames),wds.nodes.ID');

plot(G,'EdgeLabel',G.Edges.edgeNames);
end