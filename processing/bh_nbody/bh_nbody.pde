// ### parameters
int size             = 800;
int fps              = 30;

int num              = 1000; 
float G              = 1.0;
float threshold      = 0.5; // lower is slower and closer to the O(n), higher is faster but less accurate
boolean showQuads    = false;

// ###
ArrayList<Particle> particles = new ArrayList<Particle>(num);
float sum = 0.0;

void setup()
{
  size(size, size);
  noStroke();
  frameRate(fps);

  for (int i = 0; i < num; i++)
  {
    float theta = random(0, 6.283184);
    float cosine = cos(theta);
    float sine = sin(theta);

    PVector position = new PVector(size/2, size/2);
    PVector displace = new PVector(cosine, sine); // randomly rotated unit vector
    displace.mult(random(0, size/2));
    position.add(displace);

    Particle p = new Particle(0.0, new int[]{0, 0, 0}, null, null);
    p.itsPos   = position; 
    p.itsVel   = new PVector(0, 0);

    p.itsMass  = random(1, 5);
    p.itsColor = new int[]{int(random(180, 255)), int(random(180, 255)), int(random(180, 255))};

    particles.add(p);
  }
}

void mouseClicked()
{
  for (int i = 0; i < 500; i++)
  {
    float theta = random(0, 6.283184);
    float cosine = cos(theta);
    float sine = sin(theta);

    PVector position = new PVector(mouseX, mouseY);
    PVector displace = new PVector(cosine, sine); // randomly rotated unit vector
    displace.mult(random(1, 80));
    position.add(displace);

    Particle p = new Particle(0.0, new int[]{0, 0, 0}, null, null);
    p.itsPos   = position; 
    p.itsVel   = new PVector(0, 0);

    p.itsMass  = random(1, 5);
    p.itsColor = new int[]{int(random(180, 255)), int(random(180, 255)), int(random(180, 255))};

    particles.add(p);
  }
}

void draw()
{
  background(0);
  float start = millis();
  drawFast();
  sum += (millis() - start);
  float avg = sum / frameCount;

  text("Particle count: " + particles.size(), 3, 15);
  text("Average frame time: " + int(avg) + " ms", 3, 30);
}

void drawFast()
{
  QNode root = new QNode(null, new PVector(0, 0), size);

  for (Particle p : particles)
  {
    // insert the particle into the quad tree
    root.insert(p);

    // draw the particle
    set((int)p.itsPos.x, (int)p.itsPos.y, color(p.itsColor[0], p.itsColor[1], p.itsColor[2]));
  }

  if (showQuads)
  {
    stroke(50, 50, 50);
    noFill();
    drawQuad(root);
  }

  for (Particle p : particles)
  {
    root.updateForces(p);
    p.move();
    //p.clamp(0, size);
  }
}

void drawSlow()
{
  for (Particle p : particles)
  {
    for (Particle p2 : particles)
    {
      if (p == p2)
        continue;

      // Fg = GMpMj/r^2
      // Fp = Mp*a = GMpMj/r^2
      // a  = GMj/r^2
      // v  = a*t
      // v  = GMj/r^2 * 1/fps = GMj/(r^2 * fps)

      PVector v = PVector.sub(p2.itsPos, p.itsPos);
      float r = v.mag();

      float mag = G*p2.itsMass/(r*fps);

      v.normalize();
      v.mult(mag);

      p.itsVel.add(v); 
    }

    // make sure we don't go outside the window boundaries 
    //p.itsPos.x = constrain(p.itsPos.x, p.itsSize/2, size-p.itsSize/2);
    //p.itsPos.y = constrain(p.itsPos.y, p.itsSize/2, size-p.itsSize/2);

    p.move();

    set((int)p.itsPos.x, (int)p.itsPos.y, color(p.itsColor[0], p.itsColor[1], p.itsColor[2]));
  }
}

void drawQuad(QNode which)
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

/*********************************************************
 ************************         ************************
 ***********************  Classes  ***********************
 ************************         ************************
 *********************************************************/

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

  void insert(Particle p)
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

  void updateForces(Particle p)
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

  void subdivide()
  {
    float length = this.itsRegionLength/2;
    this.nw = new QNode(null, this.itsTopleft, length);
    this.ne = new QNode(null, new PVector(this.itsTopleft.x + length, this.itsTopleft.y), length);
    this.sw = new QNode(null, new PVector(this.itsTopleft.x, this.itsTopleft.y + length), length);
    this.se = new QNode(null, new PVector(this.itsTopleft.x + length, this.itsTopleft.y + length), length);
  }

  boolean isLeaf()
  {
    return (this.nw == null &&
            this.ne == null &&
            this.sw == null &&
            this.se == null);
  }

  boolean contains(Particle p)
  {
    return (p.x() >= this.itsTopleft.x && p.x() <= this.itsTopleft.x + this.itsRegionLength &&
            p.y() >= this.itsTopleft.y && p.y() <= this.itsTopleft.y + this.itsRegionLength);
  }
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

  void move()
  {
    // add velocity to position
    this.itsPos.add(this.itsVel);
  }

  void clamp(float min, float max)
  {
    // make sure we don't go outside the window boundaries 
    this.itsPos.x = constrain(this.itsPos.x, min, max);
    this.itsPos.y = constrain(this.itsPos.y, min, max);
  }

  float x()
  {
    return this.itsPos.x;
  }

  float y()
  {
    return this.itsPos.y;
  }
}