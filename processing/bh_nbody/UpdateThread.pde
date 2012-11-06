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

  void run()
  {
    float maxSpeed = 10.0;
    for (int i = start; i < end; i++)
    {
      Particle p = particles.get(i);
      node.updateForces(p);
      p.move();
    }
  }
}

