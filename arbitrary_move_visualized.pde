float CHARGE = 25;
float SPRINGFORCE = 0.1;
int NUM_OF_INITIAL_NODES = -1;
float LINKDIST= 40;
int NODE_REPULSE = 1;
int WALL_REPULSE = 1;
float MAXVEL = 1.2;
int NODE_SEP_DIST = 200; //canvas computation value
int NODE_SEP = 50;
int ORPHAN = -1;
int FIRST_DISPLAY = 7000;
int COLOR_INC = 3000;
int COLOR_TIME = FIRST_DISPLAY + COLOR_INC;
int REJOIN_DISPLAY = COLOR_TIME + 5000;
int UNCOLOR_TIME = REJOIN_DISPLAY + COLOR_INC;
int Time;
int deltaTime;
color RED = color(255, 0, 0);
color BLACK = color(0, 0, 0);
color BLUE = color(51, 51, 255);
int NUM_OF_NODES = -1;
ArrayList<Node> nodeList; // = new Node[8];
Node rejoin1;
Node rejoin2;
Table pr;
NodeList NL;
Node root;
NodeList subTree = null;
Node splitNode;
Node joinNode;
int nextNewNode =0;
int Internal = 0;
int splitFileRow = 0;
boolean frozen = false;
boolean DEBUG = true;

void mouseClicked( ) { //pause/play by mouse click
  if (frozen) {
    frozen = false;
    Time = millis() + deltaTime;
    loop();
  } else {
    frozen = true;
    noLoop();
  }
} // mouseClicked

void setup() {
  background(255);
  strokeWeight(3);
  //load adjacency matrix
  Table adjMatrix = loadTable("adjMatrixFirstMove.csv");
  NUM_OF_INITIAL_NODES = adjMatrix.getRowCount(); //inital number of nodes
  NL = new NodeList(NUM_OF_INITIAL_NODES); //create NodeList size of initial nodes
  root = NL.makeConnections(adjMatrix);
  NL.assignNodeNames();
  NL.assignParents(root);
  NL.setDisplay();
  NL.drawNeighbors(root);
  NL.connect();
  NL.repel();
  NL.unset_drawn(root);
  NL.displayNodes(root);
  pr = loadTable("output.csv"); // node to split and where to rejoin
  splitNode = NL.extractSplitJoin(pr, joinNode, splitFileRow); // in first column of pr table
  Time = millis();
  deltaTime = 0;
} // setup


void draw() {
  if (!frozen) { //if not paused
    background(255);
    NL.connect();
    NL.repel();
    NL.unset_drawn(root);
    NL.updateNodeList();
    NL.displayNodes(root);
    if (deltaTime > FIRST_DISPLAY) {
      if (!splitNode.colored && deltaTime < COLOR_TIME) {
        NL.colorize(splitNode, RED); //color subtree to split red
      }
      if (deltaTime > COLOR_TIME) {
        if (subTree == null && !NL.splitState) {
          println("split at time " + deltaTime);
          subTree = NL.splitUp(splitNode, joinNode);
        }
        if (NL.splitState) {
          subTree.unset_drawn();
          subTree.displayNodes( );
          if (deltaTime > REJOIN_DISPLAY) {
            NL.rejoin(subTree, rejoin1, rejoin2);
            NL.colorize(splitNode, BLACK);
            splitFileRow++;
            println("splitFileRow = " + splitFileRow);
            if (splitFileRow < pr.getRowCount()) {
              splitNode = NL.extractSplitJoin(pr, joinNode, splitFileRow);
            }
            Time = millis();
            deltaTime = 0;
            NL.splitState = false;
            subTree = null;
          }
        }
      }
    }
    // deltaTime = millis();
    if (splitFileRow < pr.getRowCount()) {
      deltaTime = millis() - Time;
    }
  }
}


class Node {
  float xLoc;
  float yLoc;
  Node parent;
  int parentNum;
  int nodeNum;
  String nodeName;
  int depth;
  color nodeColor;
  PVector vel;
  PVector loc;
  IntList connections = new IntList();
  boolean drawn;
  boolean colored;
  boolean nabesDrawn;
  boolean dontDraw = false;
  Node attachment;
  Node(int num) {
    connections = new IntList();
    parentNum = ORPHAN;
    nodeNum = num;
    depth = 0;
    loc = new PVector (width/2, height/2);
    vel = new PVector(0, 0);
    drawn = false;
    nabesDrawn = false;
    colored = false;
  }


  void updateNode() {
    vel.x = constrain(vel.x, -MAXVEL, MAXVEL);
    vel.y = constrain(vel.y, -MAXVEL, MAXVEL);
    loc.add(vel);
    vel = new PVector(0, 0);
  } // updateNode


  void displayNodeCircle() {
    fill(nodeColor);
    //if (connections.size() <= 1 ) {
    textSize(20);
    text(nodeName, loc.x, loc.y);
    // }
    fill(0);
  } //displayNodeCircle
} //node Class


class NodeList {
  int myWIDTH = 600;
  int myHEIGHT = 400;
  int maxConnectedNode;
  int maxDepth = -1; // max tree leaf depth, root (currently maxConnectedNode = 0
  int[] levelWidth;
  int maxLevlWidth = 0;
  int[] slot_used;
  int[] levelLocs;
  boolean splitState;
  Node rootNode;
  NodeList() {
  }
  NodeList(Node n) {
    rootNode = n;
    maxConnectedNode = n.nodeNum;
    splitState = false;
    //assignParents(n);
  }
  NodeList(int numNodes) {
    maxConnectedNode = -1;
    NUM_OF_NODES = numNodes;
    splitState = false;
    nodeList = new ArrayList<Node>(numNodes);
  }
  Node extractSplitJoin(Table rovingNodes, Node joiner, int row) {
    String splitNode = rovingNodes.getRow(row).getString(0);
    println("spltnode = " + splitNode);
    Node laterFriend = findNode(rovingNodes.getRow(row).getString(1), rootNode);
    Node splitMe = findNode(splitNode, rootNode);
    joiner = laterFriend;
    joinNode = laterFriend;
    rejoin2 = laterFriend;
    return splitMe;
  } //extractSplitJoin


  void colorize(Node splitMe, color C) { //determine which color nodes display
    if (splitMe.nodeColor != C) {
      //dbug("IN COLORIZE\n");
      colorNodes(splitMe, C);
      if (C == BLACK) {
        colorNodes(rejoin2, C);
      } else {
        colorNodes(rejoin2, BLUE);
      }
    }
  } // colorize


  void colorNodes(Node N, color C) { //color displayed nodes
    N.nodeColor = C;
    if (C == BLACK) {
      N.colored = false;
    } else {
      N.colored = true;
    }
    if (N == rejoin2) {
      return;
    }
    for (int i = 0; i < N.connections.size (); i++) {
      if (N.connections.get(i) != N.parentNum) {
        colorNodes(nodeList.get(N.connections.get(i)), C);
      }
    }
  } // colorNodes

  NodeList splitUp(Node splitMe, Node laterFriend) { //prune tree
    //dbug("IN SPLITUP\n");
    Node splitFrom = splitMe.parent;
    Node splitKid = null;
    Node splitDad = null;
    for (int i = 0; i < splitMe.connections.size (); i++) {
      if (splitMe.connections.get(i) == splitFrom.nodeNum) {
        splitMe.connections.remove(i);
      }
    }
    for (int i = 0; i < splitFrom.connections.size (); i++) {
      if (nodeList.get(splitFrom.connections.get(i)).nodeNum == splitMe.nodeNum) {
        splitFrom.connections.remove(i);
        splitMe.parent = null;
        splitMe.parentNum = ORPHAN;
        break;
      }
    }
    splitMe.attachment = laterFriend;
    laterFriend.attachment = splitMe;
    rejoin1 = splitMe;
    rejoin2 = laterFriend;
    NodeList newTree = new NodeList(splitMe);
    splitState = true;
    if (splitFrom.connections.size() == 2) {
      splitKid = nodeList.get(splitFrom.connections.get(0));
      if (splitKid.parent != splitFrom) {
        splitKid = nodeList.get(splitFrom.connections.get(1));
        splitDad = nodeList.get(splitFrom.connections.get(0));
      } else {
        splitDad = nodeList.get(splitFrom.connections.get(1));
      }
    }
    for (int i = 0; i < splitDad.connections.size (); i++) {
      if (splitDad.connections.get(i) == splitFrom.nodeNum) {
        splitDad.connections.set(i, splitKid.nodeNum);
        splitKid.parentNum = splitDad.nodeNum;
        splitKid.parent = splitDad;
        for (int j = 0; j < splitKid.connections.size (); j++) {
          if (splitKid.connections.get(j) == splitFrom.nodeNum) {
            splitKid.connections.set(j, splitDad.nodeNum);
          }
        }
      }
      //splitFrom =null;
      splitFrom.dontDraw = true;
    }
    return newTree;
  } // splitUp


  void rejoin(NodeList Nlist, Node n1, Node n2) { //regraft subtree
    //dbug("IN REJOIN\n
    noLoop();
    n1.attachment = null;
    n2.attachment = null;
    //find n2's parent
    Node n2dad = n2.parent;
    Node newNode = new Node(nodeList.size());
    newNode.nodeName = "N" + Internal; //nodeList.size();
    Internal++;
    if (n2dad == null) { // n2 is root
      n2.connections.append(newNode.nodeNum);
      NL.rootNode = newNode;
    } else { //n2 is not root => has a parent
      newNode.parent = n2dad;
      newNode.parentNum = n2dad.nodeNum;
      newNode.connections = new IntList();
      for (int i = 0; i < n2dad.connections.size (); i++) {
        if (n2dad.connections.get(i) == n2.nodeNum) {
          n2dad.connections.set(i, newNode.nodeNum);
          newNode.connections.append(n2dad.nodeNum);
        }
      }
      for (int i = 0; i < n2.connections.size (); i++) {
        if (n2.connections.get(i) == n2dad.nodeNum) {
          n2.connections.set(i, newNode.nodeNum);
        }
      }
    } //n2 is not root => has a parent
    newNode.connections.append(n2.nodeNum);
    newNode.attachment = n2.attachment;
    n2.attachment = null;
    n2.parent = newNode;
    n2.parentNum = newNode.nodeNum;
    nodeList.add(newNode);
    NUM_OF_NODES++;
    n1.connections.append(newNode.nodeNum);
    newNode.connections.append(n1.nodeNum);
    Nlist = null; // null out now-rejoined subtree; allow garbage collect
    rejoin1.parent = newNode;
    rejoin1.parentNum = newNode.nodeNum;
    splitState = false;
    newNode.loc = n1.loc.get();
    newNode.loc.lerp(n2.loc, 0.5);
    loop();
  } //rejoin (...)



  Node findNode(String splitName, Node curNode) {
    for (int i=0; i < nodeList.size (); i++) {
      if (nodeList.get(i).nodeName.equals(splitName)) {
        return nodeList.get(i);
      }
    }
    return null;
  } // findNode


  Node makeConnections(Table adjMatrix) {
    Node returnNode = null;
    levelWidth = new int[NUM_OF_NODES];
    for (int i = 0; i < NUM_OF_NODES; i++) {
      levelWidth[i] = 0;
    }
    int val;
    for (int row = 0; row < NUM_OF_NODES; row++) {
      nodeList.add(new Node(row));
      for (int col = 0; col < NUM_OF_NODES; col++) {
        val = adjMatrix.getInt(row, col); //get value in matrix
        print(val);
        if (val == 1) {
          nodeList.get(row).connections.append(col);
          if (maxConnectedNode == -1 ||
            nodeList.get(row).connections.size() > nodeList.get(maxConnectedNode).connections.size()) {
            maxConnectedNode = row;
          }
        }
      }
      println();
    }
    returnNode = nodeList.get(maxConnectedNode);
    rootNode = returnNode;
    return returnNode;
  } // makeConnections


  void assignParents(Node n) {
    for (int i = 0; i < n.connections.size (); i++) {
      if (n.connections.get(i) != n.parentNum) {
        nodeList.get(n.connections.get(i)).parent = n;
        // println("Just assigned " + n.nodeNum + " as " + n.connections.get(i) + " parent. ");
        nodeList.get(n.connections.get(i)).parentNum = n.nodeNum;
        nodeList.get(n.connections.get(i)).depth = n.depth + 1;
        levelWidth[nodeList.get(n.connections.get(i)).depth]++;
        maxLevlWidth = max(maxLevlWidth, levelWidth[nodeList.get(n.connections.get(i)).depth]);
        maxDepth = max(maxDepth, n.depth + 1);
        // println(n.connections.get(i) + " depth = " + nodeList[n.connections.get(i)].depth);
        assignParents(nodeList.get(n.connections.get(i)));
      }
    }
  } // assignParents


  void assignNodeNames() {
    Table nodeNames = loadTable("nodenames.csv");
    TableRow row;
    int NI;
    String NN;
    for (int nn = 0; nn < nodeList.size (); nn++) {
      nodeList.get(nn).nodeName = "" + nn;
    }
    for (int i = 0; i < nodeNames.getRowCount (); i++) {
      //println (nodeList[nodeNames.getRow(i).getInt(0)].nodeNum);
      row = nodeNames.getRow(i);
      print(row.getInt(0));
      NI = row.getInt(0);
      NN = row.getString(1);
      nodeList.get(NI).nodeName = NN;
      println(row.getString(1));
    }
  } // assignNodeNames


  void setDisplay() {
    myHEIGHT = maxDepth * NODE_SEP_DIST; //set height
    myWIDTH = maxLevlWidth * NODE_SEP_DIST; //set width
    size(myWIDTH, myHEIGHT);
    nodeList.get(maxConnectedNode).loc = new PVector(myWIDTH/2.0, 10);
    nodeList.get(maxConnectedNode).displayNodeCircle();
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
      Node nabeNode = nodeList.get((n.connections.get(i)));
      if (!nabeNode.drawn) { // if neighbor not already drawn
        nabeNode.yLoc = (nabeNode.depth + 1) * NODE_SEP; //level 1 is at 50, 2 at 100 (for y coordinate)
        nabeNode.xLoc = levelLocs[slot_used[nabeNode.depth]];
        slot_used[nabeNode.depth]++;
        nabeNode.loc.set(nabeNode.xLoc, nabeNode.yLoc);
        nabeNode.drawn = true;
      }
    }
    n.nabesDrawn = true;
    for (int i = 0; i < n.connections.size (); i++) {
      drawNeighbors(nodeList.get(n.connections.get(i)));
    }
    // println("size = " + n.connections.size());
  } // drawNeighbors



  void connect() { 

    for (int i = 0; i < NUM_OF_NODES; i++) {
      Node hp = nodeList.get(i);
      Node jhp = hp.parent;
      if (jhp != null) {
        attract(hp, jhp);
      }
      if (hp.attachment != null) {
        attractStronger(hp, hp.attachment);
      }
    }
  } // connect


    void attract(Node hp, Node jhp) { //Hooke's Law
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
  } // attract


  void attractStronger(Node hp, Node jhp) {
    PVector diff = PVector.sub(hp.loc, jhp.loc); // Calculate vector pointing away from neighbor
    diff.normalize();
    float distance = PVector.dist(hp.loc, jhp.loc); // weight by Hooke's law
    // println("distance = " + distance);
    diff.mult( Hooke(distance) );
    // println("hook =" + Hooke(distance));
    hp.vel.add(diff); // forces accelerate the individual
    diff = PVector.sub(jhp.loc, hp.loc); // Calculate vector pointing away from neighbor
    diff.normalize();
    distance = PVector.dist(jhp.loc, hp.loc); // weight by Hooke's law
    diff.mult( Hooke(distance) );
    jhp.vel.add(diff); // forces accelerate the individual
  } // attract
  // pairwise repulsion between haplotypes


  void repel() { //Coloumb's Law
    for (int i = 0; i < NUM_OF_NODES; i++) {
      Node hp = nodeList.get(i);
      PVector push = new PVector(0, 0);
      float distance;
      PVector diff;
      // repel from other Haplotypes
      for (int j = 0; j < NUM_OF_NODES; j++) {
        if (i != j && nodeList.get(i).attachment != nodeList.get(j)) {
          Node jhp = nodeList.get(j);
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


  void unset_drawn() {
    unset_drawn(rootNode);
  } //unset_drawn


  void unset_drawn(Node n) {
    n.drawn = false;
    n.nabesDrawn = false;
    for (int i = 0; i < n.connections.size (); i++) {
      Node nabeNode = nodeList.get((n.connections.get(i)));
      nabeNode.drawn = false;
      nabeNode.nabesDrawn = false;
      if (n.parent != nabeNode) {
        unset_drawn(nabeNode);
      }
    }
    for (int i = 0; i < NUM_OF_NODES; i++) {
      nodeList.get(i).updateNode();
    }
  } // unset_drawn


  void updateNodeList() {
    for (int i = 0; i < NUM_OF_NODES; i++) {
      nodeList.get(i).updateNode();
    }
  } // updateNodeList


  void displayNodes() {
    displayNodes(rootNode);
  }//displayNodes


  void displayNodes (Node n) {
    if (n.nabesDrawn) {
      return;
    }
    n.displayNodeCircle();
    n.drawn = true;
    for (int i = 0; i < n.connections.size (); i++) {
      Node nabeNode = nodeList.get((n.connections.get(i)));
      if (!nabeNode.drawn) { // if neighbor not already drawn
        nabeNode.displayNodeCircle();
        drawNabeLine(n.nodeNum, n.connections.get(i));
        nabeNode.drawn = true;
      }
    }
    n.nabesDrawn = true;
    for (int i = 0; i < n.connections.size (); i++) {
      displayNodes(nodeList.get(n.connections.get(i)));
    }
    // println("size = " + n.connections.size());
  } // displayNodes


  void drawNabeLine (int nabe1, int nabe2) { // draw between nodelist entries
    stroke(BLACK);
    if (nodeList.get(nabe1).parent != nodeList.get(nabe2)) {
      if (nodeList.get(nabe1).nodeColor == nodeList.get(nabe2).nodeColor) {
        stroke(nodeList.get(nabe1).nodeColor);
      }
      line(nodeList.get(nabe1).loc.x, nodeList.get(nabe1).loc.y, 
      nodeList.get(nabe2).loc.x, nodeList.get(nabe2).loc.y);
    }
  } // drawNabeLine
} // class NodeList


float Hooke (float dist) { //Hooke's Law
  float force;
  force = SPRINGFORCE *(LINKDIST - dist);
  return force;
}


float coulomb(float dist) { //Coulomb's Law
  float force;
  if (dist > 0) {
    force = sq(CHARGE) / sq(dist);
  } else {
    force = 10000;
  }
  return force; //return the force of hooke's law
}


void dbug (String s) {
  if (DEBUG) {
    println(s);
  }
}
