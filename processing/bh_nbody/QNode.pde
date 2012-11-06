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
