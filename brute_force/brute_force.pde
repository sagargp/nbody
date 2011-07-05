float G = 1e-5;
ParticleSystem ps;

void setup() {
	size(1024, 768);
	colorMode(RGB, 255, 255, 255, 100);
	smooth();
	ps = new ParticleSystem();
}

void draw() {
	background(0);
	ps.run();
}

class ParticleSystem {
	ArrayList particles;

	ParticleSystem() {
		particles = new ArrayList();

		for (int i = 0; i < 1000; i++) {
			int m = (int) random(1e3, 1e5);
			int r = 1;
			Particle p = new Particle(m, r, new PVector(random(1024), random(768), 0), new PVector(0, 0, 0));
			particles.add(p);
		}
		
		Particle star = new Particle(1e9, 10, new PVector(512, 384, 0), new PVector(0, 0, 0));
		particles.add(star);
		
	}

	void run() {
		// calculate the forces on every particle from every other one
		for (int i = 0; i < particles.size(); i++) {
			PVector accel = new PVector(0, 0, 0);
			Particle p1 = (Particle) particles.get(i);

			for (int j = 0; j < particles.size(); j++) {
				if (i == j)
				continue;

				Particle p2 = (Particle) particles.get(j);

				PVector direction = PVector.sub(p2.position, p1.position);
				direction.normalize();
				float a = G * p2.mass / (sq(p1.position.dist(p2.position)) + sq(3e2));

				PVector acceleration = PVector.mult(direction, a);
				accel.add(acceleration);
			}
			p1.acceleration = accel;
			p1.update();
			p1.render();
		}
	}
}

class Particle {
	PVector position;
	PVector velocity;
	PVector acceleration;

	float mass;
	int radius;

	Particle(float mass, int radius, PVector position, PVector initial_velocity) {
		this.position = position;
		this.mass = mass;
		this.velocity = initial_velocity;
		this.radius = radius;
	}

	void run() {
		update();
		render();
	}

	void update() {
		velocity.add(acceleration);
		position.add(velocity);
	}

	void render() {
		ellipseMode(CENTER);
		stroke(255, 100);
		fill(100, 100);

		ellipse(position.x, position.y, radius, radius);
	}
}
