# -------------------------------------------------------------------------------
# Name:        module2
# Purpose:
#
# Author:      gpayz_000
#
# Created:     17/07/2014
# Copyright:   (c) gpayz_000 2014
# Licence:     <your licence>
# -------------------------------------------------------------------------------
import numpy
from numpy import ndarray
import pydot
from ete2 import Tree
from Bio import Phylo
from cStringIO import StringIO


def main():
    pass


if __name__ == '__main__':
    main()

# treedata = "(A, (B, C)Z, (D, E));"
# treedata = "((D,F)E,(B,H)B);"
treedata = "(A,B,(C,D)E)F;"

t = Tree(treedata, format=1)
print "Original tree looks like this:"
print t.get_ascii(show_internal=True)
E = t.search_nodes(name="E")[0]
A = t.search_nodes(name="A")[0]
E_removed_node = E.detach()
# A_removed_node = A.detach()
# F = t.search_nodes(name="F")[0]
# twelve = A.add_child(name="12", dist=1.0)

# twelve.add_child(name="11")
# twelve.add_child(A_removed_node)
print "New tree looks like this:"
print t.get_ascii(show_internal=True)
midMoveTree = t
#print t
#for node in t.traverse("postorder"):
# Do some analysis on node
#print node.name
# twelve.add_child(E)
# A.delete(twelve)
A.add_child(E_removed_node, dist=1.0)
print "Regrafted tree looks like this"
print  t.get_ascii(show_internal=True)

##def to_adjacency_matrix (tree):
##
##   allclades = list(tree.find_clades(order = 'level'))
##   lookup = {}
##   for i, elem in enumerate(allclades):
##       lookup[elem] = i
##   adjmat = numpy.zeros((len(allclades), len(allclades)), dtype='S1')
##   dim = len(adjmat)
##   #sadjmat = ndarray((dim, dim), numpy.dtype('S1'))
##   graph = pydot.Dot(graph_type='graph')
##   for parent in tree.find_clades(terminal=False, order='level'):
##       for child in parent.clades:
##           adjmat[lookup[parent], lookup[child]] = parent.name # 1
##           edge = pydot.Edge(lookup[parent], lookup[child])
##           graph.add_edge(edge)
##   graph.write_png('example1_graph.png')
##   if not tree.rooted:
##       # Branches can go from "child" to "parent" in unrooted trees
##       #added () after transpose
##       adjmat += adjmat.transpose()
##   #return (allclades, numpy.matrix(adjmat))
##   return adjmat

def to_adjacency_matrix(tree):
    fo = open("nodenames.csv", "w")
    fo.write("0, " + treedata[-2] + "," + '\n')
    allclades = list(tree.find_clades(order='level'))
    lookup = {}
    for i, elem in enumerate(allclades):
        lookup[elem] = i
    adjmat = numpy.zeros((len(allclades), len(allclades)))
    graph = pydot.Dot(graph_type='graph')
    for parent in tree.find_clades(terminal=False, order='level'):
        for child in parent.clades:
            if parent.name is not None:
                fo.write(str(lookup[parent]) + ", " + parent.name + "," + '\n')

            if child.name is not None:
                fo.write(str(lookup[child]) + ", " + child.name + "," + '\n')
            adjmat[lookup[parent], lookup[child]] = 1
            edge = pydot.Edge(lookup[parent], lookup[child])
            graph.add_edge(edge)
    graph.write_png('example1_graph.png')
    if not tree.rooted:
        # Branches can go from "child" to "parent" in unrooted trees
        #added () after transpose
        adjmat += adjmat.transpose()
    #return (allclades, numpy.matrix(adjmat))
    fo.close()
    return adjmat


from cStringIO import StringIO

# handle = StringIO(treedata)
# treeToTest = Phylo.read(handle, "newick")
treeToTest = t.write(format=8)
handle = StringIO(treeToTest)
treeToTest = Phylo.read(handle, "newick")
# Phylo.draw_graphviz(treeToTest)

#print(to_adjacency_matrix (treeToTest))
a = to_adjacency_matrix(treeToTest)

numpy.savetxt("adjMatrixFirstMove.csv", a, delimiter=",")
