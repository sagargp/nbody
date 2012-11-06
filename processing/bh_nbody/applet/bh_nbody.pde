import controlP5.*;

ControlP5 controlP5;

// ### parameters
int size             = 1000;
int fps              = 30;
int num              = 15000; 
float G              = 0.5;
float threshold      = 2.0; // lower is slower and closer to the O(n), higher is faster but less accurate
boolean showQuads    = false;
boolean running      = false;

// ###
ArrayList<Particle> particles = new ArrayList<Particle>(num);
float lastTime = 0.0;
boolean useFast = true;

void setup()
{
  controlP5 = new ControlP5(this);

  Radio algorithmSelection = controlP5.addRadio("algorithm", 3, 45);
  algorithmSelection.addItem("Slow", 0);
  algorithmSelection.addItem("Fast", 1);
  algorithmSelection.activate("Fast");

  CheckBox quads = controlP5.addCheckBox("quads", 3, 75);
  quads.addItem("show quads", 0);
  
  controlP5.addSlider("gravity",   0.0, 10.0, 1.0, 3, 100, 200, 20);
  controlP5.addSlider("threshold", 0.0, 20.0, 0.5, 3, 125, 200, 20);
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

void mouseClicked()
{
  if (mouseEvent.getClickCount() == 2)
    addParticles(
      10000, // how many
      new PVector(mouseX, mouseY), // where
      10, // spread
      10 // tangential velocity
    );
}

void draw()
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
  text("Frame time: " + int(avg) + " ms", 3, 30);
}

void drawFast()
{
  QNode root = new QNode(null, new PVector(-2*size, -2*size), 5*size);
  float maxSpeed = 10.0;

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

void drawSlow()
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

void addParticles(int howMany, PVector where, float spread, float tangentialVelocity)
{
  int[] rand = new int[]{int(random(100, 255)), int(random(100, 255)), int(random(100, 255))};
  float mass = (rand[0] + rand[1] + rand[2])/765f;
  for (int i = 0; i < howMany; i++)
  {
    float theta      = random(0, 6.283184);
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
    showQuads = (event.group().arrayValue()[0] == 1.0);
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


