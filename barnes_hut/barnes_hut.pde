double G = 1e-5;
double S = 3e2; // "softening parameter"
int L = 1000; // length of the simulation (always square)
boolean drawQuads = false;

NBody nbody;

void setup() {
	size(L, L);
	colorMode(RGB, 255, 255, 255, 100);
	smooth();
	
	nbody = new NBody();
}

void draw() {
	background(0);
	nbody.run();
}

void drawQuadrants(BHNode node) {
	if (node.NW == null)
		rect(node.quad.topLeft.x, node.quad.topLeft.y, (float)node.quad.length, (float)node.quad.length);
	else {
		drawQuadrants(node.NW);
		drawQuadrants(node.NE);
		drawQuadrants(node.SW);
		drawQuadrants(node.SE);
	}
}

class NBody {
	ArrayList particles = new ArrayList();
	BHNode root;
	
	NBody() {
		for (int i = 0; i < 1000; i++) {
			//Particle p = new Particle(random(1e3, 1e5), new PVector(480 + random(40), 480 + random(40)), new PVector(-5 + random(10), -5 + random(10), 0));
                        Particle p = new Particle(random(1e3, 1e5), new PVector(random(L), random(L)), new PVector(0, 0));
			particles.add(p);
		}
		
		Particle star = new Particle(1e5, new PVector(L/2, L/2), new PVector(0, 0));
		particles.add(star);
	}
	
	void run() {
		root = new BHNode(new Quadrant(new PVector(0, 0), L));
		
		for (int i = 0; i < particles.size(); i++) {
			Particle p = (Particle)particles.get(i);
			p.resetForces();
			root.insert(p);
		}
		
		for (int i = 0; i < particles.size(); i++) {
			Particle p = (Particle)particles.get(i);
			
			root.updateForce(p);
			p.update();
			p.render();
		}

                if (drawQuads) {
                  fill(100, 0);
                  stroke(100, 50);
                  drawQuadrants(root);
                }
	}
}

class Quadrant {
	private PVector topLeft;
	public double length;
	
	Quadrant(PVector topLeft, double length) {
		this.topLeft = topLeft;
		this.length = length;
	}
	
	// returns TRUE if this Quadrant contains the point (x, y)
	boolean contains(double x, double y) {
		if (x >= topLeft.x && x <= topLeft.x + length
			&& y >= topLeft.y && y <= topLeft.y + length)
			return true;
		return false;
	}
	
	boolean contains(Particle p) {
		double x = p.position.x;
		double y = p.position.y;
		
		if (x >= topLeft.x && x <= topLeft.x + length
			&& y >= topLeft.y && y <= topLeft.y + length)
			return true;
		return false;
	}

	Quadrant NW() {
		return new Quadrant(topLeft, length/2);
	}
	
	Quadrant NE() {
		PVector shift = new PVector((float)length/2.0, 0.0);
		return new Quadrant(PVector.add(topLeft, shift), length/2);
	}
	
	Quadrant SW() {
		PVector shift = new PVector(0.0, (float)length/2.0);
		return new Quadrant(PVector.add(topLeft, shift), length/2);
	}
	
	Quadrant SE() {
		PVector shift = new PVector((float)length/2.0, (float)length/2.0);
		return new Quadrant(PVector.add(topLeft, shift), length/2);
	}
}

class BHNode {
	private Particle particle;
	private Quadrant quad;
	private BHNode NW, NE, SW, SE;
	
	BHNode(Quadrant q) {
		this.quad = q;
	}

	void insert(Particle p) {
		if (NW == null && particle == null && quad.contains(p)) {
			particle = p;
			return;
		}
		
		if (NW == null && particle != null && quad.contains(p)) {
			// subdivide the quad
			NW = new BHNode(quad.NW());
			NE = new BHNode(quad.NE());
			SW = new BHNode(quad.SW());
			SE = new BHNode(quad.SE());

			// move the original particle to the appropriate quad
			insert(this.particle);
			
			// set this node's particle to be the average of the two incoming ones
			this.particle = p.addTo(particle);
			
			// move the new particle to the appropriate quad
			insert(p);
			return;
		}
		
		if (NW.quad.contains(p))
			NW.insert(p);
		else if (NE.quad.contains(p))
			NE.insert(p);
		else if (SW.quad.contains(p))
			SW.insert(p);
		else if (SE.quad.contains(p))
			SE.insert(p);
	}
	
	void updateForce(Particle p) {
		if (this.particle == null)
			return;
		
		if (NW == null) { // check if this is a leaf node
			p.addForce(this.particle);
		} else {
			double s = this.quad.length;
			double d = this.particle.distanceTo(p);
			
			if (s/d < 0.5) {
				p.addForce(this.particle);
			} else {
				NW.updateForce(p);
				NE.updateForce(p);
				SW.updateForce(p);
				SE.updateForce(p);
			}
		}
	}
}

class Particle {
	float mass;
	PVector position;
	PVector velocity;
	PVector force;
	
	Particle(float mass, PVector position, PVector initial_velocity) {
		this.mass = mass;
		this.position = position;
		this.velocity = initial_velocity;
        this.force = new PVector(0, 0);
	}
	
	void resetForces() {
		this.force = new PVector(0, 0);
	}
	
	// add this particle to another one and return a new particle
	Particle addTo(Particle b) {
		float m = mass + b.mass;
		
		//(a*Ma + b*Mb) / m
		PVector pos = PVector.div(PVector.add(PVector.mult(position, mass), PVector.mult(b.position, b.mass)), m);
		return new Particle(m, pos, new PVector(0, 0));
	}
	
	void update() {
		PVector accel = PVector.div(force, (float)mass);
		velocity.add(accel);
		position.add(velocity);
	}
	
	void render() {
		ellipseMode(CENTER);
		stroke(255, 100);
		fill(100, 100);
		ellipse(position.x, position.y, 1, 1);
	}

	// calculate the effect of the forces from p on this particle
	void addForce(Particle p) {
		PVector direction = PVector.sub(p.position, this.position);
		//direction.normalize();
		double f = G * p.mass * this.mass / ( sq((float)this.distanceTo(p)) + sq((float)S) );
		PVector force = PVector.mult(direction, (float)f);
		this.force.add(force);
	}

	double distanceTo(Particle p) {
		return position.dist(p.position);
	}
	
	boolean in(Quadrant q) {
		return q.contains(position.x, position.y);
	}
}
