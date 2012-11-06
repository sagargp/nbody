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
