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

def to_adjacency_matrix(tree):
    fo = open("nodenames.csv", "w")
    fo.write("0," + treedata[-2] + "," + '\n')
    allclades = list(tree.find_clades(order='level'))
    lookup = {}
    for i, elem in enumerate(allclades):
        lookup[elem] = i
    adjmat = numpy.zeros((len(allclades), len(allclades)))
    graph = pydot.Dot(graph_type='graph')
    for parent in tree.find_clades(terminal=False, order='level'):
        for child in parent.clades:
            if parent.name is not None:
                fo.write(str(lookup[parent]) + "," + parent.name + "," + '\n')

            if child.name is not None:
                fo.write(str(lookup[child]) + "," + child.name + "," + '\n')
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

def main():
    pass

if __name__ == '__main__':
    main()

# treedata = "(A, (B, C)Z, (D, E));"
# treedata = "((D,F)E,(B,H)B);"
# treedata = "(A(B(C,D(E))F(G,H)));"  # "(A,B,(C,D)E)F;"
treedata = "(C,D,(E,F)A,(G,H,I)B)R;"
parenCount = treedata.count(")")
lastParen = 0
for i in range(parenCount):
    parenPos = treedata.find(")", lastParen + 1)
    tempTree = treedata
    treedata = tempTree[:parenPos + 1] + str(i) + tempTree[parenPos + 1:]
    lastParen = parenPos
print "treedata = " + treedata

t = Tree(treedata, format=1)
Internal = 0
print "Original tree looks like this:"
print t.get_ascii(show_internal=True)
# handle = StringIO(treedata)
# treeToTest = Phylo.read(handle, "newick")
treeToTest = t.write(format=8)
handle = StringIO(treeToTest)
treeToTest = Phylo.read(handle, "newick")
# Phylo.draw_graphviz(treeToTest)

#print(to_adjacency_matrix (treeToTest))
a = to_adjacency_matrix(treeToTest)

numpy.savetxt("adjMatrixFirstMove.csv", a, delimiter=",")

# E = t.search_nodes(name="0A")[0]
A = t.search_nodes(name="C")[0]
detach_leaves = ["G", "H"]
if len(detach_leaves) == 1:
    ancestor = t.search_nodes(name=detach_leaves[0])[0]
else:
    ancestor = t.get_common_ancestor(detach_leaves)
print "ancestor:"
print ancestor.name #not printing
removed_node = ancestor.detach()


print "New tree looks like this:"
print t.get_ascii(show_internal=True)
midMoveTree = t

reattachNode = t.get_common_ancestor("D")
Ddad = (t&"D").up
newNode = Ddad.add_child(name="N" + str(Internal))
D = (t&"D")
D.detach()
newNode.add_child(D)
Internal = Internal + 1

newNode.add_child(removed_node, dist=1.0)
print "Regrafted tree looks like this"
print t.get_ascii(show_internal=True)


import csv
RESULT = [ancestor.name,'D']
resultFile = open("output.csv",'wb')
wr = csv.writer(resultFile, dialect='excel')
wr.writerow(RESULT)





