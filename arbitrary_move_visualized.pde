float CHARGE = 25; //<>//
float SPRINGFORCE = 0.1;
int NUM_OF_TOTAL_NODES = -1;
float LINKDIST= 40;
int NODE_REPULSE = 1;
int WALL_REPULSE = 1;
float MAXVEL = 1.2;
int NODE_SEP_DIST = 200; //canvas computation value
int NODE_SEP = 50;
NodeList NL;
Node root;

boolean DEBUG = true;

void setup() {

  background(255);

  //load csv file
  Table adjMatrix = loadTable("adjMatrixFirstMove.csv");
  NUM_OF_TOTAL_NODES = adjMatrix.getRowCount();
  NL = new NodeList(NUM_OF_TOTAL_NODES);
  root = NL.makeConnections(adjMatrix);
  NL.assignNodeNames();
  NL.assignParents(root);
  NL.setDisplay();
  NL.drawNeighbors(root);
  NL.connect();
  NL.repel();
  NL.unset_drawn(root);
  NL.displayNodes(root);
} // setup

void draw() {
  background(255);
  NL.connect();
  NL.repel();
  NL.unset_drawn(root);
  NL.updateNodeList();
  NL.displayNodes(root);
}




class Node {

  float xLoc;
  float yLoc;
  Node parent;
  int parentNum;
  int nodeNum;
  String nodeName;
  int depth;
  PVector vel;
  PVector loc;
  IntList connections = new IntList();
  boolean drawn;
  boolean nabesDrawn;

  Node(int num) {
    connections = new IntList();
    parentNum = -1;
    nodeNum = num;
    depth = 0;
    loc = new PVector (width/2, height/2);
    vel = new PVector(0, 0);
    drawn = false;
    nabesDrawn = false;
  }

  // int findParent() {
  // Table adjMatrix = loadTable("adjMatrix.csv");
  // int val;
  // for (int col = 0; col < 8; col++) {
  // val = adjMatrix.getInt(nodeNum, col);
  // if ( val == 1) {
  // this.parentNum = val;
  //
  // break;
  // }
  // }
  // return parentNum;
  // }

  // void findChildren() {
  // int val;
  // Table adjMatrix = loadTable("adjMatrix.csv");
  // for (int col = (this.nodeNum - 1); col < 8; col++) {
  // val = adjMatrix.getInt(nodeNum, col);
  // if ( val == 1 ) {
  // this.connections.append(val);
  // }
  // }
  // }

  // void branchConnection() {
  // PVector diff = PVector.sub(this.xLoc, this.yLoc,0,0);
  // }

  void updateNode() {
    vel.x = constrain(vel.x, -MAXVEL, MAXVEL);
    vel.y = constrain(vel.y, -MAXVEL, MAXVEL);
    loc.add(vel);
    vel = new PVector(0, 0);
  } // updateNode

  void displayBranch(PVector endLoc) {
    stroke(0);
    strokeWeight(10);
    //line(loc.x, loc.y, parent.loc.x, parent.loc.y);
    line(loc.x, loc.y, endLoc.x, endLoc.y); //line connecting nodes
  }

  void displayNodeCircle() {
    // fill(255);
    // //ellipse(loc.x, loc.y, rad*2, rad*2);
    // ellipse(loc.x, loc.y, 10, 10); //draw node circle
    fill(0);
    //text(""+nodeNum, loc.x, loc.y);
    text(nodeName, loc.x, loc.y);
  }
}

class NodeList {
  Node[] nodeList; // = new Node[8];
  int myWIDTH = 600;
  int myHEIGHT = 400;
  int maxConnectedNode = -1;
  int maxDepth = -1; // max tree leaf depth, root (currently maxConnectedNode = 0
  int[] levelWidth;
  int maxLevlWidth = 0;
  int[] slot_used;
  int[] levelLocs;
  int NUM_OF_NODES = -1;

  NodeList() {
  }

  NodeList(Node n) {
    assignParents(n);
  }

  NodeList(int numNodes) {
    this.NUM_OF_NODES = numNodes;
    nodeList = new Node[numNodes];
  }

  Node makeConnections(Table adjMatrix) {
    Node returnNode = null;
    levelWidth = new int[NUM_OF_NODES];
    for (int i = 0; i < NUM_OF_NODES; i++) {
      levelWidth[i] = 0;
    }
    int val;
    for (int row = 0; row < NUM_OF_NODES; row++) {
      nodeList[row] = new Node(row);
      for (int col = 0; col < NUM_OF_NODES; col++) {
        val = adjMatrix.getInt(row, col); //get value in matrix
        print(val);
        if (val == 1) {
          nodeList[row].connections.append(col);
          if (maxConnectedNode == -1 ||
            nodeList[row].connections.size() > nodeList[maxConnectedNode].connections.size()) {
            maxConnectedNode = row;
          }
        }
      }
      println();
    }
    returnNode = nodeList[maxConnectedNode];
    return returnNode;
  } // makeConnections

  void assignParents(Node n) {
    for (int i = 0; i < n.connections.size (); i++) {
      if (n.connections.get(i) != n.parentNum) {
        nodeList[n.connections.get(i)].parent = n;
        // println("Just assigned " + n.nodeNum + " as " + n.connections.get(i) + " parent. ");
        nodeList[n.connections.get(i)].parentNum = n.nodeNum;
        nodeList[n.connections.get(i)].depth = n.depth + 1;
        levelWidth[nodeList[n.connections.get(i)].depth]++;
        maxLevlWidth = max(maxLevlWidth, levelWidth[nodeList[n.connections.get(i)].depth]);
        maxDepth = max(maxDepth, n.depth + 1);
        // println(n.connections.get(i) + " depth = " + nodeList[n.connections.get(i)].depth);
        assignParents(nodeList[n.connections.get(i)]);
      }
    }
  } // assignParents

  void assignNodeNames() {
    Table nodeNames = loadTable("nodenames.csv");
    TableRow row;
    int NI;
    String NN;
    for (int nn = 0; nn < nodeList.length; nn++) {
      nodeList[nn].nodeName = "" + nn;
    }
    for (int i = 0; i < nodeNames.getRowCount (); i++) {
      //println (nodeList[nodeNames.getRow(i).getInt(0)].nodeNum);
      row = nodeNames.getRow(i);
      print(row.getInt(0));
      NI = row.getInt(0);
      NN = row.getString(1);
      nodeList[NI].nodeName = NN;
      println(row.getString(1));
      //println (nodeList[nodeNames.getRow(i).getString(1));
      //println(nodenames.getRow(i).getString(1));
      //nodeList[nodeNames.getRow(i).getInt(0)].nodeNum = nodeNames.getRow(i).getString(1);
      //nodeList[nodeNames.getRow(i).getInt(0)]
      // .nodeName = nodeNames.getRow(i).getString(1)];
    }
  } // assignNodeNames

  void setDisplay() {
    myHEIGHT = maxDepth * NODE_SEP_DIST; //set height
    myWIDTH = maxLevlWidth * NODE_SEP_DIST; //set width
    size(myWIDTH, myHEIGHT);
    nodeList[maxConnectedNode].loc = new PVector(myWIDTH/2.0, 10);
    nodeList[maxConnectedNode].displayNodeCircle();
    levelLocs = new int[maxLevlWidth];
    for (int i = 0; i < maxLevlWidth; i++) {
      levelLocs[i] = i*myWIDTH/(i+1);
    }
    slot_used = new int[maxDepth + 1];
    for (int i = 0; i < maxDepth; i++) {
      slot_used[i] = 0;
    }
  } // setDisplayDims

  void drawNeighbors (Node n) {
    if (n.nabesDrawn) {
      return;
    }
    // println("max connected node is " + n.nodeNum);
    // println();
    n.drawn = true;
    if (DEBUG) {
      // println(n.nodeNum + " connects to: ");
      for (int i = 0; i < n.connections.size (); i++) {
        // print (n.connections.get(i) + " ");
      }
      // println();
    }
    for (int i = 0; i < n.connections.size (); i++) {
      Node nabeNode = nodeList[(n.connections.get(i))];
      if (!nabeNode.drawn) { // if neighbor not already drawn
        //if NODE_SEP = 50
        nabeNode.yLoc = (nabeNode.depth + 1) * NODE_SEP; //level 1 is at 50, 2 at 100 (for y coordinate)
        nabeNode.xLoc = levelLocs[slot_used[nabeNode.depth]];
        slot_used[nabeNode.depth]++;
        nabeNode.loc.set(nabeNode.xLoc, nabeNode.yLoc);

        nabeNode.drawn = true;
      }
    }
    n.nabesDrawn = true;
    for (int i = 0; i < n.connections.size (); i++) {
      drawNeighbors(nodeList[n.connections.get(i)]);
    }
    // println("size = " + n.connections.size());
  } // drawNeighbors

  // connection between linked haplotypes
  void connect() {

    for (int i = 0; i < NUM_OF_NODES; i++) {

      Node hp = nodeList[i];
      Node jhp = hp.parent;


      if (jhp != null) {

        PVector diff = PVector.sub(hp.loc, jhp.loc); // Calculate vector pointing away from neighbor
        diff.normalize();
        float distance = PVector.dist(hp.loc, jhp.loc); // weight by Hooke's law
        // println("distance = " + distance);
        diff.mult( Hooke(distance) );
        // println("hook =" + Hooke(distance));
        hp.vel.add(diff); // forces accelerate the individual
        // println(hp.vel);
        // println("diff = " +diff );

        diff = PVector.sub(jhp.loc, hp.loc); // Calculate vector pointing away from neighbor
        diff.normalize();
        distance = PVector.dist(jhp.loc, hp.loc); // weight by Hooke's law
        diff.mult( Hooke(distance) );
        jhp.vel.add(diff); // forces accelerate the individual
        // println("hp.loc.x = " + hp.loc.x);
      }
    }
  } // connect

  // pairwise repulsion between haplotypes
  void repel() {

    for (int i = 0; i < NUM_OF_NODES; i++) {

      Node hp = nodeList[i];
      PVector push = new PVector(0, 0);
      float distance;
      PVector diff;

      // repel from other Haplotypes
      for (int j = 0; j < NUM_OF_NODES; j++) {
        if (i != j) {

          Node jhp = nodeList[j];
          // Calculate vector pointing away from neighbor
          diff = PVector.sub(hp.loc, jhp.loc);
          diff.normalize();
          // weight by Coulomb's law
          distance = PVector.dist(hp.loc, jhp.loc);
          diff.mult( NODE_REPULSE*coulomb(distance) );
          push.add(diff);
        }
      }

      // repel from left wall
      diff = new PVector(1, 0);
      distance = hp.loc.x-0;
      diff.mult( WALL_REPULSE*coulomb(distance) );
      push.add(diff);

      // repel from right wall
      diff = new PVector(-1, 0);
      distance = width-hp.loc.x;
      diff.mult( WALL_REPULSE*coulomb(distance) );
      push.add(diff);

      // repel from top wall
      diff = new PVector(0, 1);
      distance = hp.loc.y-0;
      diff.mult( WALL_REPULSE*coulomb(distance) );
      push.add(diff);

      // repel from bottom wall
      diff = new PVector(0, -1);
      distance = height-hp.loc.y;
      diff.mult( WALL_REPULSE*coulomb(distance) );
      push.add(diff);

      // forces accelerate the individual
      hp.vel.add(push);
    }
  } // repel

  void unset_drawn(Node n) {
    n.drawn = false;
    n.nabesDrawn = false;
    for (int i = 0; i < n.connections.size (); i++) {
      Node nabeNode = nodeList[(n.connections.get(i))];
      nabeNode.drawn = false;
      nabeNode.nabesDrawn = false;
      if (n.parent != nabeNode) {
        unset_drawn(nabeNode);
      }
    }
    for (int i = 0; i < NUM_OF_NODES; i++) {
      nodeList[i].updateNode();
    }
  } // unset_drawn


  void updateNodeList() {
    for (int i = 0; i < NUM_OF_NODES; i++) {
      nodeList[i].updateNode();
    }
  } // updateNodeList

  void displayNodes (Node n) {
    if (n.nabesDrawn) {
      return;
    }
    n.displayNodeCircle();
    n.drawn = true;
    if (DEBUG) {
      // println(n.nodeNum + " connects to: ");
      for (int i = 0; i < n.connections.size (); i++) {
        // print (n.connections.get(i) + " ");
      }
      // println();
    }
    for (int i = 0; i < n.connections.size (); i++) {
      Node nabeNode = nodeList[(n.connections.get(i))];
      if (!nabeNode.drawn) { // if neighbor not already drawn
        nabeNode.displayNodeCircle();
        drawNabeLine(n.nodeNum, n.connections.get(i));
        nabeNode.drawn = true;
      }
    }
    n.nabesDrawn = true;
    for (int i = 0; i < n.connections.size (); i++) {
      displayNodes(nodeList[n.connections.get(i)]);
    }

    // println("size = " + n.connections.size());
  } // displayEm

  void drawNabeLine (int nabe1, int nabe2) { // draw between nodelist entries
    line(nodeList[nabe1].loc.x, nodeList[nabe1].loc.y, 
    nodeList[nabe2].loc.x, nodeList[nabe2].loc.y);
  } // drawNabeLine
} // class NodeList



float Hooke (float dist) {
  float force;
  force = SPRINGFORCE *(LINKDIST - dist);
  return force;
}

float coulomb(float dist) {
  float force;
  if (dist > 0) {
    force = sq(CHARGE) / sq(dist);
  } else {
    force = 10000;
  }
  return force;
}

void dbug (String s) {
  if (DEBUG) {
    println(s);
  }
}
