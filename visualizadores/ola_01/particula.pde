class Particula {
  int r, g, b, a;
  PVector posicion, velocidad, aceleracion, gravedad;
  float limite;
  float masa;
  boolean resistencia;
  float coefroz;
  float lifespan;
  boolean eterna;
  int decay;

  Particula() {
    posicion    = new PVector(random(width), random(height));
    velocidad   = new PVector(0, 0);
    aceleracion = new PVector(0, 0);
    gravedad    = new PVector(0, 0.02);
    limite   = 15;
    masa     = random(3, 18);
    resistencia = false;
    r = int(random(0, 255));
    g = int(random(0, 255));
    b = int(random(0, 255));
    a = int(random(0, 255));
    lifespan = 255;
    eterna   = false;
    decay    = 2;
  }

  void acelerar(PVector acelerador) {
    PVector ac = PVector.div(acelerador, masa);
    aceleracion.add(ac);
  }

  void caer() {
    velocidad.add(gravedad);
  }

  boolean muerta() {
    return lifespan < 0;
  }

  void actualizar() {
    if (!eterna) lifespan -= decay;
    velocidad.add(aceleracion);
    if (resistencia) {
      PVector friccion = velocidad.get();
      friccion.normalize();
      friccion.mult(-1 * coefroz);
      velocidad.add(friccion);
    }
    velocidad.limit(limite);
    posicion.add(velocidad);
    aceleracion.mult(0);

    if (posicion.x > width)  { velocidad.x *= -1; posicion.x = width;  }
    if (posicion.x < 0)      { velocidad.x *= -1; posicion.x = 0;      }
    if (posicion.y > height) { velocidad.y *= -1; posicion.y = height; }
    if (posicion.y < 0)      { velocidad.y *= -1; posicion.y = 0;      }
  }

  void lanzar() {
    actualizar();
  }
}


class Astilla extends Particula {
  float angular;

  Astilla(PVector origen, PVector vinicial, float masap) {
    super();
    posicion.set(origen);
    masa     = masap;
    velocidad = vinicial;
    angular  = 0;
  }

  void mostrar() {
    if (!eterna) a = int(lifespan);
    stroke(r, g, b, a);
    strokeWeight(1);
    fill(r, g, b, a);
    angular = velocidad.heading() + PI;
    rectMode(CENTER);
    pushMatrix();
    translate(posicion.x, posicion.y);
    rotate(angular);
    rect(0, 0, 2*masa, masa);
    popMatrix();
  }

  void lanzar() {
    actualizar();
    mostrar();
  }
}
