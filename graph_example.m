clear all, close all

%s = [1 1 1 1 2 2 3 1 1];
%t = [1 1 2 4 3 4 4 1 1];
%edgeNames = {'First', 'Second', 'Third' ,'Fourth'}';
%nodeNames  = {'loop1' 'loop2' 'Hi' 'Hello' 'Bonjour' 'Welcome' 'Salut' 'loop3' 'loop4'}';

s=[1     2     3     6     4     2     5     3];
t=[2     3     4     1     7     5     4     5];
edgeNames = {'p1', 'p2','p3','pump4','p5','p6','p7','p8'}';
nodeNames ={'n1','n2','n3','n4','n5','rI','rII'}';

G = digraph(s, t, table(edgeNames), nodeNames);
plot(G, 'EdgeLabel', G.Edges.edgeNames)

G.Edges.edgeNames
