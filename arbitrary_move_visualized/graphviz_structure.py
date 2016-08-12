import numpy
import pydot
from Bio import Phylo


def to_adjacency_matrix (tree):

   allclades = list(tree.find_clades(order = 'level'))
   lookup = {}
   for i, elem in enumerate(allclades):
       lookup[elem] = i
   adjmat = numpy.zeros((len(allclades), len(allclades)))
   graph = pydot.Dot(graph_type='graph')
   for parent in tree.find_clades(terminal=False, order='level'):
       for child in parent.clades:
           adjmat[lookup[parent], lookup[child]] = 1
           edge = pydot.Edge(lookup[parent], lookup[child])
           graph.add_edge(edge)
   graph.write_png('example1_graph.png')
   if not tree.rooted:
       # Branches can go from "child" to "parent" in unrooted trees
       #added () after transpose
       adjmat += adjmat.transpose()
   #return (allclades, numpy.matrix(adjmat))
   return adjmat


from cStringIO import StringIO

treedata = "(A, (B, C), (D, E))"
handle = StringIO(treedata)
treeToTest = Phylo.read(handle, "newick")
# Phylo.draw_graphviz(treeToTest)

#print(to_adjacency_matrix (treeToTest))
a = to_adjacency_matrix (treeToTest)


numpy.savetxt("adjMatrix.csv", a, delimiter = ",")
