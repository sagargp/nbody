import processing.core.*; 
import processing.xml.*; 

import controlP5.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class bh_nbody extends PApplet {



ControlP5 controlP5;

// ### parameters
int size             = 1000;
int fps              = 30;
int num              = 15000; 
float G              = 0.5f;
float threshold      = 2.0f; // lower is slower and closer to the O(n), higher is faster but less accurate
boolean showQuads    = false;
boolean running      = false;

// ###
ArrayList<Particle> particles = new ArrayList<Particle>(num);
float lastTime = 0.0f;
boolean useFast = true;

public void setup()
{
  controlP5 = new ControlP5(this);

  Radio algorithmSelection = controlP5.addRadio("algorithm", 3, 45);
  algorithmSelection.addItem("Slow", 0);
  algorithmSelection.addItem("Fast", 1);
  algorithmSelection.activate("Fast");

  CheckBox quads = controlP5.addCheckBox("quads", 3, 75);
  quads.addItem("show quads", 0);
  
  controlP5.addSlider("gravity",   0.0f, 10.0f, 1.0f, 3, 100, 200, 20);
  controlP5.addSlider("threshold", 0.0f, 20.0f, 0.5f, 3, 125, 200, 20);
  controlP5.addButton("clear", 0, 3, 150, 35, 20);
  controlP5.addButton("startstop", 0, 3, 175, 55, 20);

  size(1680, 900);
  noStroke();
  frameRate(fps);

  addParticles(
    num, // how many
    new PVector(840, 450), // where
    10, // spread
    10 // tangential velocity
  );
}

public void mouseClicked()
{
  if (mouseEvent.getClickCount() == 2)
    addParticles(
      10000, // how many
      new PVector(mouseX, mouseY), // where
      10, // spread
      10 // tangential velocity
    );
}

public void draw()
{
  background(0);
  float start = millis();
  if (useFast)
    drawFast();
  else
    drawSlow();
  float diff = millis() - start;
  float avg = (lastTime + diff)/2;
  lastTime = diff;

  fill(255);
  text("Particle count: " + particles.size(), 3, 15);
  text("Frame time: " + PApplet.parseInt(avg) + " ms", 3, 30);
}

public void drawFast()
{
  QNode root = new QNode(null, new PVector(-2*size, -2*size), 5*size);
  float maxSpeed = 10.0f;

  for (Particle p : particles)
  {
    // insert the particle into the quad tree
    root.insert(p);

    // draw the particle
    float mag = p.itsVel.mag();
    set((int)p.itsPos.x, (int)p.itsPos.y, color(
          mag/maxSpeed*p.itsColor[0],
          mag/maxSpeed*p.itsColor[1],
          mag/maxSpeed*p.itsColor[2])
       );
  }

  if (showQuads)
  {
    stroke(50, 50, 50);
    noFill();
    drawQuad(root);
  }

  if (running)
  {
    new UpdateThread(root, particles, 0*particles.size()/5, 1*particles.size()/5).start();
    new UpdateThread(root, particles, 1*particles.size()/5, 2*particles.size()/5).start();
    new UpdateThread(root, particles, 2*particles.size()/5, 3*particles.size()/5).start();
    new UpdateThread(root, particles, 3*particles.size()/5, 4*particles.size()/5).start();
    new UpdateThread(root, particles, 4*particles.size()/5, 5*particles.size()/5).start();

    /*for (Particle p : particles)
    {
      root.updateForces(p);
      p.move();
    }*/
  }
}

public void drawSlow()
{
  for (Particle p : particles)
  {
    for (Particle p2 : particles)
    {
      if (p == p2)
        continue;

      PVector v = PVector.sub(p2.itsPos, p.itsPos);
      float r = v.mag();

      float mag = G*p2.itsMass/(r*fps);

      v.normalize();
      v.mult(mag);

      p.itsVel.add(v); 
    }
    p.move();
    set((int)p.itsPos.x, (int)p.itsPos.y, color(p.itsColor[0], p.itsColor[1], p.itsColor[2]));
  }
}

public void drawQuad(QNode which)
{
  rect(which.itsTopleft.x, which.itsTopleft.y, which.itsRegionLength, which.itsRegionLength);

  if (!which.isLeaf())
  {
    drawQuad(which.nw);
    drawQuad(which.ne);
    drawQuad(which.sw);
    drawQuad(which.se);
  }
}

public void addParticles(int howMany, PVector where, float spread, float tangentialVelocity)
{
  int[] rand = new int[]{PApplet.parseInt(random(100, 255)), PApplet.parseInt(random(100, 255)), PApplet.parseInt(random(100, 255))};
  float mass = (rand[0] + rand[1] + rand[2])/765f;
  for (int i = 0; i < howMany; i++)
  {
    float theta      = random(0, 6.283184f);
    float cosine     = cos(theta);
    float sine       = sin(theta);

    PVector position = new PVector(where.x, where.y);
    PVector displace = new PVector(cosine, sine); // randomly rotated unit vector
    PVector velocity = PVector.mult(new PVector(-displace.y, displace.x), tangentialVelocity);

    displace.mult(random(0, spread));
    position.add(displace);

    particles.add(new Particle(mass, rand, position, velocity));
  }
}

/***************************************************
 ********************          *********************
 *****************  C5 Callbacks  ******************
 ********************          *********************
 ***************************************************/
public void controlEvent(ControlEvent event)
{
  if (event.isGroup())
    showQuads = (event.group().arrayValue()[0] == 1.0f);
}

public void clear(int value)
{
  particles.clear();
}

public void startstop()
{
  running = !running;
}

public void algorithm(int which)
{
  useFast = which == 1;
}

public void gravity(float value)
{
  G = value;
}

public void threshold(float value)
{
  this.threshold = value;
}


class Particle
{
  float itsMass;
  int itsColor[];
  PVector itsPos;
  PVector itsVel;

  Particle(float itsMass, int itsColor[], PVector itsPos, PVector itsVel)
  {
    this.itsMass  = itsMass;
    this.itsColor = itsColor;
    this.itsPos   = itsPos;
    this.itsVel   = itsVel;
  }

  public void move()
  {
    // add velocity to position
    this.itsPos.add(this.itsVel);
  }

  public void clamp(float min, float max)
  {
    // make sure we don't go outside the window boundaries 
    this.itsPos.x = constrain(this.itsPos.x, min, max);
    this.itsPos.y = constrain(this.itsPos.y, min, max);
  }

  public float x()
  {
    return this.itsPos.x;
  }

  public float y()
  {
    return this.itsPos.y;
  }
}
class QNode
{
  // actual particle (if leaf) or CoM
  Particle itsParticle;
  float itsMass;

  // this node's region data
  PVector itsTopleft;
  float itsRegionLength;

  QNode nw, ne, sw, se;

  QNode(Particle p)
  {
    this.itsParticle = p;
    if (p != null)
      this.itsMass = p.itsMass;
  }

  QNode(Particle p, PVector tl, float length)
  {
    this.itsParticle = p;
    if (p != null)
      this.itsMass = p.itsMass;
    this.itsTopleft = tl;
    this.itsRegionLength = length;
  }

  public void insert(Particle p)
  {
    /* if this node doesn't contain a body,
     *    set itsParticle = p
     *    return
     * else if this node has children already,
     *    update the center of mass info
     *    recursively insert(p) at the right child
     * else if this node has no children (but does contain a body)
     *    subdivide()
     *    this.insert(p)
     */

    if (this.itsParticle == null)
    {
      this.itsParticle = p;
      this.itsMass = p.itsMass;
    }
    else if (!this.isLeaf())
    {
      float M = this.itsMass + p.itsMass;
      this.itsParticle = 
        new Particle(M, null,
            new PVector(
              (this.itsParticle.x() * this.itsMass + p.x() * p.itsMass)/M,
              (this.itsParticle.y() * this.itsMass + p.y() * p.itsMass)/M
              ), null);

      this.itsMass = itsParticle.itsMass;

      // nw
      if (this.nw.contains(p)) this.nw.insert(p);

      // ne
      if (this.ne.contains(p)) this.ne.insert(p);

      // sw
      if (this.sw.contains(p)) this.sw.insert(p);

      // se
      if (this.se.contains(p)) this.se.insert(p);
    }
    else
    {
      this.subdivide();
      this.insert(p);
    }
  }

  public void updateForces(Particle p)
  {
    /* if this node has no children (and it's also not representative of p)
     *    calculate the force from this node to p
     * else if s/d < threshold
     *    calculate the force from this node to p without recursing
     * else
     *    recursively call updateForces on my children
     */

    if (this.itsParticle == p || this.itsParticle == null)
      return;

    float sd_ratio = this.itsRegionLength/p.itsPos.dist(this.itsParticle.itsPos);

    if (this.isLeaf() || sd_ratio <= threshold)
    {
      PVector v = PVector.sub(this.itsParticle.itsPos, p.itsPos);
      float r   = v.mag();
      float mag = (G*this.itsMass/(r*fps));

      v.normalize();
      v.mult(mag);

      p.itsVel.add(v);
    }
    else
    {
      this.nw.updateForces(p);
      this.ne.updateForces(p);
      this.sw.updateForces(p);
      this.se.updateForces(p);
    }
  }

  public void subdivide()
  {
    float length = this.itsRegionLength/2;
    this.nw = new QNode(null, this.itsTopleft, length);
    this.ne = new QNode(null, new PVector(this.itsTopleft.x + length, this.itsTopleft.y), length);
    this.sw = new QNode(null, new PVector(this.itsTopleft.x, this.itsTopleft.y + length), length);
    this.se = new QNode(null, new PVector(this.itsTopleft.x + length, this.itsTopleft.y + length), length);
  }

  public boolean isLeaf()
  {
    return (this.nw == null &&
        this.ne == null &&
        this.sw == null &&
        this.se == null);
  }

  public boolean contains(Particle p)
  {
    return (p.x() >= this.itsTopleft.x && p.x() <= this.itsTopleft.x + this.itsRegionLength &&
        p.y() >= this.itsTopleft.y && p.y() <= this.itsTopleft.y + this.itsRegionLength);
  }
}
class UpdateThread extends Thread
{
  QNode node;
  ArrayList<Particle> particles;
  int start, end;

  UpdateThread(QNode node, ArrayList<Particle> p, int start, int end)
  {
    this.node = node;
    this.particles = p;
    this.start = start;
    this.end = end;
  }

  public void run()
  {
    float maxSpeed = 10.0f;
    for (int i = start; i < end; i++)
    {
      Particle p = particles.get(i);
      node.updateForces(p);
      p.move();
    }
  }
}

  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#FFFFFF", "bh_nbody" });
  }
}
