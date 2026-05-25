class Atractor {
  PVector posicion;
  PVector home;
  PVector vel;
  float sentido;
  int tipo_atractor;

  Atractor(int clase) {
    posicion = new PVector(0, 0);
    home     = new PVector(0, 0);
    vel      = new PVector(0, 0);
    sentido  = -1;
    tipo_atractor = clase;
  }

  // Fija la posición actual como posición de reposo
  void fijarHome() {
    home.set(posicion);
  }

  // Impulso elástico en dirección aleatoria (beat)
  void impulso(float mag) {
    float ang = random(TWO_PI);
    vel.x += cos(ang) * mag;
    vel.y += sin(ang) * mag;
  }

  // Oscilación sinusoidal + retorno elástico al home
  // t: tiempo (frameCount), freq: frecuencia rad/frame, phase: desfase
  // amp: amplitud de la oscilación en px
  void springUpdate(float t, float freq, float phase, float amp) {
    float ox = cos(t * freq + phase)        * amp;
    float oy = sin(t * freq * 1.17 + phase + 1.3) * amp * 0.75;
    PVector target = new PVector(home.x + ox, home.y + oy);

    PVector spring = PVector.sub(target, posicion);
    spring.mult(0.06);
    vel.add(spring);
    vel.mult(0.88);
    posicion.add(vel);

    // mantener dentro de pantalla
    posicion.x = constrain(posicion.x, 50, width  - 50);
    posicion.y = constrain(posicion.y, 50, height - 50);
  }

  PVector fuerza(PVector posicionobjeto) {
    PVector f = posicionobjeto.get();
    f.sub(posicion);
    float modulo = f.mag();
    f.normalize();
    switch (tipo_atractor) {
      case 1: f.mult(modulo / 50);           break;
      case 2: f.mult(150 / modulo);          break;
      case 3: f.mult(4);                     break;
      case 4: f.mult(150 / modulo*modulo);   break;
    }
    f.mult(sentido);
    return f;
  }

  void visible() {
    stroke(255);
    strokeWeight(1);
    noFill();
    ellipse(posicion.x, posicion.y, 10, 10);
  }
}
